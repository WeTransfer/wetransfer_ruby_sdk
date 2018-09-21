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
        add_items_to_remote_board(items: builder.items, remote_board: board)
      rescue LocalJumpError
        raise ArgumentError, 'No items where added to the board'
      end

      def get_board(board_id:)
        request_board(board_id)
      end

      def create_remote_board(board)
        authorize_if_no_bearer_token!
        response = faraday.post(
          '/v2/boards',
          JSON.pretty_generate(board.to_initial_request_params),
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        remote_board = RemoteBoard.new(JSON.parse(response.body, symbolize_names: true))
        board.items.any? ? add_items_to_remote_board(items: board.items, remote_board: remote_board) : remote_board
      end

      def add_items_to_remote_board(items:, remote_board:)
        items.group_by(&:class).each do |_, grouped_items|
          grouped_items.each do |item|
            item.add_to_board(client: self, remote_board: remote_board)
          end
        end
        binding.pry
        remote_board
      end

      def request_board(board_id)
        authorize_if_no_bearer_token!
        response = faraday.get(
          "/v2/boards/#{board_id}",
          {},
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        RemoteBoard.new(JSON.parse(response.body, symbolize_names: true))
      end

    end
  end
end
