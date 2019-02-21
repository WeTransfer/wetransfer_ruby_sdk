module WeTransfer
  class Transfer
    class DuplicateFileNameError < ArgumentError; end
    class NoFilesAddedError < StandardError; end

    include CommunicationHelper

    def self.create(message:, &block)
      transfer = new(message: message)

      transfer.persist(&block)
    end

    def initialize(message:)
      @message = message
      @files = []
      @unique_file_names = Set.new
    end

    # Add files (if still needed)
    def persist
      yield(self) if block_given?

      create_remote_transfer

      ## files should now be in persisted status

    end

    # Add one or more files to a transfer, so a transfer can be created over the
    # WeTransfer public API
    #
    # @param name [String] (nil) the name of the file
    #
    # @return [WeTransfer::Client]
    def add_file(name: nil, size: nil, io: nil)
      file = WeTransferFile.new(name: name, size: size, io: io)
      raise DuplicateFileNameError unless @unique_file_names.add?(file.name.downcase)

      @files << file
      self
    end

    private

    def as_json_request_params
      {
        message: @message,
        files: @files.map(&:as_json_request_params),
      }
    end

    def create_remote_transfer
      raise NoFilesAddedError if @unique_file_names.empty?

      response = request_as.post(
        '/v2/transfers',
        as_json_request_params.to_json,
        {}
      )
      ensure_ok_status!(response)

      @remote_transfer = RemoteTransfer.new(JSON.parse(response.body, symbolize_names: true))
    end
  end
end
