module WeTransfer
  class Client
    module Transfers

      def create_transfer(message:)
        builder = TransferBuilder.new
        yield(builder)
        future_transfer = FutureTransfer.new(message: message, files: builder.items)
        create_remote_transfer(future_transfer)
      rescue LocalJumpError
        raise ArgumentError, 'No items where added to transfer'
      end

      def complete_transfer(transfer:)
        complete_transfer_call(transfer)
      end

      def get_transfer(transfer_id:)
        request_transfer(transfer_id)
      end
    end
  end
end
