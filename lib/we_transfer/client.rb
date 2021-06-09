# frozen_string_literal: true

module WeTransfer
  class Client
    class Error < StandardError; end
    extend Forwardable

    # Initialize a WeTransfer::Client
    #
    # @param api_key [String] The API key you want to authenticate with
    #
    # @return [WeTransfer::Client]
    def initialize(api_key:)
      @communicator = Communicator.new(api_key)
    end

    def create_transfer(**args, &block)
      transfer = WeTransfer::Transfer.new(args.merge(communicator: @communicator))
      transfer.persist(&block)
    end

    def create_transfer_and_upload_files(**args, &block)
      transfer = create_transfer(args, &block)
      transfer
        .upload_files
        .complete_files
        .finalize
    end

    def_delegator :@communicator, :find_transfer
  end
end
