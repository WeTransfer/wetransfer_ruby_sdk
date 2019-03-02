# frozen_string_literal: true

module WeTransfer
  class Client
    class Error < StandardError; end
    include Communication

    NullLogger = Logger.new(nil)

    attr_reader :transfer

    # Initialize a WeTransfer::Client
    #
    # @param api_key [String] The API key you want to authenticate with
    # @param logger [Logger] (NullLogger) your custom logger
    #
    # @return [WeTransfer::Client]
    def initialize(api_key:, logger: NullLogger)
      Communication.reset_authentication!
      Communication.api_key = api_key
      Communication.logger = logger
    end

    def create_transfer(**args, &block)
      transfer = WeTransfer::Transfer.new(args)
      transfer.persist(&block)
      @transfer = transfer

      self
    end

    def create_transfer_and_upload_files(message:, &block)
      transfer = WeTransfer::Transfer.new(args)
      transfer.persist(&block)

    end

    def find_transfer(transfer_id)
      @transfer = WeTransfer::Transfer.find(transfer_id)
    end
  end
end
