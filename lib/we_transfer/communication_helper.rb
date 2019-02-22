module WeTransfer
  class CommunicationError < StandardError; end

  module CommunicationHelper
    extend Forwardable

    API_URL_BASE = "https://dev.wetransfer.com"
    DEFAULT_HEADERS = {
      "User-Agent" => "WetransferRubySdk/#{WeTransfer::VERSION} Ruby #{RUBY_VERSION}",
      "Content-Type" => "application/json"
    }.freeze

    class << self
      attr_accessor :logger, :api_key, :bearer_token

      def reset_authentication!
        @api_key = nil
        @bearer_token = nil
        @request_as = nil
      end

      def find_transfer(transfer_id)
        response = request_as.get("/v2/transfers/%s" % [transfer_id])
        ensure_ok_status!(response)
        response_body = remote_transfer_params(response.body)
        found_transfer = Transfer.new(message: response_body[:message])
        setup_transfer(
          transfer: found_transfer,
          data: response_body
        )
      end

      def upload_url_for_chunk(transfer_id, file_id, chunk)
        response = request_as.get("/v2/transfers/%s/files/%s/upload-url/%s" % [transfer_id, file_id, chunk])
        ensure_ok_status!(response)

        JSON.parse(response.body).fetch("url")
      end

      def persist_transfer(transfer)
        response = request_as.post(
          "/v2/transfers",
          transfer.as_request_params.to_json,
        )
        ensure_ok_status!(response)

        handle_new_transfer_data(
          transfer: transfer,
          data: remote_transfer_params(response.body)
        )
      end

      def finalize_transfer(transfer)
        response = request_as.put("/v2/transfers/%s/finalize" % transfer.id)
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

    def_delegator self, :minimal_faraday_config
  end
end
