module WeTransfer
  class Client
    module Boards

      def create_board(name:, description:)
        builder = BoardBuilder.new
        yield(builder) if block_given?
        future_board = FutureBoard.new(name: name, description: description, items: builder.items)
        create_remote_board(future_board)
      end

      def add_items(board:)
        builder = BoardBuilder.new
        yield(builder)
        add_items_to_remote_board(builder.items, board)
      rescue LocalJumpError
        raise ArgumentError, 'No items where added to the board'
      end

      def get_board(board_id:)
        request_board(board_id)
      end
    end
  end
end
