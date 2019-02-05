module WeTransfer
  class Transfer
    extend WeTransfer::CommunicationHelper
    include WeTransfer::CommunicationHelper

    def initialize(client:, message:)
      @client = client
      @message = message
    end

    def id
      @remote_transfer&.id
    end

    def files
      @remote_transfer.files
    end

    def create_transfer_and_upload_files(message:, &block)
      future_transfer = create_future_transfer(message: message, &block)
      @remote_transfer = create_remote_transfer(future_transfer)
      @remote_transfer.files.each do |file|
        check_for_file_duplicates(future_transfer.files, file)
        local_file = future_transfer.files.select { |x| x.name == file.name }.first
        upload_file(object: @remote_transfer, file: file, io: local_file.io)
        complete_file!(object: @remote_transfer, file: file)
      end
      finalize_transfer(transfer: @remote_transfer)
    end

    def self.get_transfer(transfer_id:, client:)
      @client = client
      response = request_as.get(
        "/v2/transfers/#{transfer_id}",
        {},
        {},
      )
      ensure_ok_status!(response)
      RemoteTransfer.new({ client: @client }.merge(JSON.parse(response.body, symbolize_names: true)))
    end

    def create_transfer(&block)
      future_transfer = create_future_transfer(&block)
      @remote_transfer = create_remote_transfer(future_transfer)
    end

    def finalize!
      response = request_as.put(
        "/v2/transfers/#{id}/finalize",
        '',
        auth_headers
      )
      ensure_ok_status!(response)
      RemoteTransfer.new({client: @client}.merge(JSON.parse(response.body, symbolize_names: true)))
    end

    # this `private` should be removed
    private

    def finalize_transfer(transfer: self)
      @client.logger.error "This method should not be called"

      finalize!
    end

    # below here is RLY private

    private

    def create_future_transfer
      builder = WeTransfer::TransferBuilder.new(transfer: self)
      yield(builder)
      FutureTransfer.new(message: @message, files: builder.files)
    rescue LocalJumpError
      raise ArgumentError, 'No files were added to transfer'
    end

    def create_remote_transfer(transfer)
      response = request_as.post(
        '/v2/transfers',
        JSON.pretty_generate(transfer.to_request_params),
      )
      ensure_ok_status!(response)
      remote_transfer_params = JSON
        .parse(response.body, symbolize_names: true)
        .merge(client: @client)

      RemoteTransfer.new(remote_transfer_params)
    end
  end
end
