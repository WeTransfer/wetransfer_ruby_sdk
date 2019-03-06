module WeTransfer
  class Client
    class Error < StandardError; end

    # Initialize a WeTransfer::Client
    #
    # @param api_key [String] The API key you want to authenticate with
    #
    # @return [WeTransfer::Client]
    def initialize(api_key:)
      @communicator = Communication.new(api_key)
    end

    def create_transfer(**args, &block)
      transfer = WeTransfer::Transfer.new(args.merge(communicator: @communicator))
      transfer.persist(&block)
    end

    def create_transfer_and_upload_files(**args, &block)
      transfer = create_transfer(args, &block)
      transfer.upload_files
      transfer.complete_files
      transfer.finalize
    end

    def find_transfer(transfer_id)
      @communicator.find_transfer(transfer_id)
    end
  end
end
