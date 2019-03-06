module WeTransfer
  class CommunicationError < StandardError; end

  class Communication
    include Logging
    extend Forwardable

    API_URL_BASE = "https://dev.wetransfer.com"
    AUTHORIZE_URI = "/v2/authorize"
    FINALIZE_URI = "/v2/transfers/%s/finalize"
    TRANSFER_URI = "/v2/transfers/%s"
    TRANSFERS_URI = "/v2/transfers"
    UPLOAD_URL_URI = "/v2/transfers/%s/files/%s/upload-url/%s"

    DEFAULT_HEADERS = {
      "User-Agent" => "WetransferRubySdk/#{WeTransfer::VERSION} Ruby #{RUBY_VERSION}",
      "Content-Type" => "application/json"
    }.freeze

    attr_accessor :api_key

    def initialize(api_key)
      @api_key = api_key
    end

    # Instantiate a transfer from a transfer id, by talking to the WeTransfer Public API
    #
    # @param  transfer_id [String] the id of the transfer you want to find
    #
    # @raise  [WeTransfer::CommunicationError] if the transfer cannot be found
    #
    # @return [WeTransfer::Transfer]
    def find_transfer(transfer_id)
      response = request_as.get(TRANSFER_URI % transfer_id)
      ensure_ok_status!(response)
      response_body = remote_transfer_params(response.body)
      found_transfer = Transfer.new(message: response_body[:message], communicator: self)
      setup_transfer(
        transfer: found_transfer,
        data: response_body
      )
    end

    # GET an URL we can PUT a chunk of a file to.
    # Note that this URL is valid for one hour, so if a lot of chunks have to be upload
    # (or a slow network is expected), take care to not request your URLs too early
    #
    # @param transfer_id [String] the id of the transfer the file belongs to
    # @param file_id [String] the id of the file the URL is requested for
    # @param chunk [String, Number] the (1 based) chunk number of the file
    #
    # @raise  [WeTransfer::CommunicationError] if the request to the WeTransfer Public API
    #         cannot be satisfied (e.g. transfer not found, file id unknown, chunk out of bound)
    #
    # @return [String] a signed URL, valid for an hour
    #
    def upload_url_for_chunk(transfer_id, file_id, chunk)
      response = request_as.get(UPLOAD_URL_URI % [transfer_id, file_id, chunk])
      ensure_ok_status!(response)

      JSON.parse(response.body).fetch("url")
    end

    # Send a request to WeTransfer's Public API to create a transfer with
    # a message and some files
    #
    # @param [Transfer] the transfer that should persist on WeTransfer
    #
    # @raise  [WeTransfer::CommunicationError] if the request to the WeTransfer Public API
    #         cannot be satisfied (e.g. transfer has no message, files with duplicate names)
    #
    # @return [WeTransfer::Transfer] the transfer as persisted on WeTransfer. Persisting a transfer
    #         changes the state of the transfer, so it is the same object that was sent in as param,
    #         but some instance variables will be different.
    #
    def persist_transfer(transfer)
      response = request_as.post(
        TRANSFERS_URI,
        transfer.as_persist_params.to_json,
      )
      ensure_ok_status!(response)

      handle_new_transfer_data(
        transfer: transfer,
        data: remote_transfer_params(response.body)
      )
    end

    # Send a request to WeTransfer's Public API to signal that all chunks of all files are done
    # uploading, and that the transfer is should be processed for download.
    #
    # @param [Transfer] the transfer that should be finalized
    #
    # @raise  [WeTransfer::CommunicationError] if the request to the WeTransfer Public API
    #         cannot be satisfied (e.g. not all chunks are uploaded, too much or too little data
    #         is uploaded)
    #
    # @return [WeTransfer::Transfer] the transfer. Finalizing changes the state of the transfer,
    #         so it is the same object that was sent in as param, but some instance variables will
    #         be different.
    #
    def finalize_transfer(transfer)
      response = request_as.put(FINALIZE_URI % transfer.id)
      ensure_ok_status!(response)
      handle_new_transfer_data(
        transfer: transfer,
        data: remote_transfer_params(response.body)
      )
    end

    def remote_transfer_params(response_body)
      JSON.parse(response_body, symbolize_names: true)
    end

    def upload_chunk(put_url, chunk_contents)
      @chunk_uploader ||= Faraday.new { |c| minimal_faraday_config(c) }

      @chunk_uploader.put(
        put_url,
        chunk_contents.read,
        'Content-Type' => 'binary/octet-stream',
        'Content-Length' => chunk_contents.size.to_s
      )
    end

    def complete_file(transfer_id, file_id, chunks)
      response = request_as.put(
        "/v2/transfers/%s/files/%s/upload-complete" % [transfer_id, file_id],
        { part_numbers: chunks }.to_json
      )

      ensure_ok_status!(response)
      remote_transfer_params(response.body)
    end

    private

    def request_as
      @request_as ||= Faraday.new(API_URL_BASE) do |c|
        minimal_faraday_config(c)
        c.headers = auth_headers.merge DEFAULT_HEADERS
      end
    end

    def setup_transfer(transfer:, data:)
      data[:files].each do |file_params|
        transfer.add_file(
          name: file_params[:name],
          size: file_params[:size],
        )
      end

      handle_new_transfer_data(transfer: transfer, data: data)
    end

    def handle_new_transfer_data(transfer:, data:)
      %i[id state url].each do |i_var|
        transfer.instance_variable_set "@#{i_var}", data[i_var]
      end

      RemoteFile.upgrade(
        transfer: transfer,
        files_response: data[:files]
      )
      transfer
    end

    def auth_headers
      authorize_if_no_bearer_token!

      {
        'X-API-Key' => api_key,
        'Authorization' => "Bearer #{@bearer_token}"
      }
    end

    def ensure_ok_status!(response)
      case response.status
      when 200..299
        true
      when 400..499
        logger.error response
        raise WeTransfer::CommunicationError, JSON.parse(response.body)["message"]
      when 500..504
        logger.error response
        raise WeTransfer::CommunicationError, "Response had a #{response.status} code, we could retry"
      else
        logger.error response
        raise WeTransfer::CommunicationError, "Response had a #{response.status} code, no idea what to do with that"
      end
    end

    def authorize_if_no_bearer_token!
      return @bearer_token if @bearer_token

      response = Faraday.new(API_URL_BASE) do |c|
        minimal_faraday_config(c)
        c.headers = DEFAULT_HEADERS.merge('X-API-Key' => api_key)
      end.post(
        '/v2/authorize',
      )
      ensure_ok_status!(response)
      bearer_token = JSON.parse(response.body)['token']
      raise WeTransfer::CommunicationError, "The authorization call returned #{response.body} and no usable :token key could be found there" if bearer_token.nil? || bearer_token.empty?
      @bearer_token = bearer_token
    end

    def minimal_faraday_config(config)
      config.response :logger, logger
      config.adapter Faraday.default_adapter
    end
  end

  # def_delegator self, :minimal_faraday_config
  # end
end
