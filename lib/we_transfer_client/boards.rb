module WeTransfer
  class Client
    module Boards

      def create_board_and_upload_files(name:, description:, board_builder: BoardBuilder, future_board_class: FutureBoard)
        builder = board_builder.new
        yield(builder) if block_given?
        future_board = future_board_class.new(name: name, description: description, items: builder.items)
        board = create_remote_board(future_board)
        board.file_items.each do |item|
          file = future_board.file_items.select { |x| x.name == item.name }.first
          upload_file(object: board, file: item, io: file.io)
          complete_file!(object: board, file: item)
        end
        board
      end

      def create_board(name:, description:, board_builder: BoardBuilder, future_board: FutureBoard)
        builder = board_builder.new
        yield(builder) if block_given?
        future_board = future_board.new(name: name, description: description, items: builder.items)
        create_remote_board(board: future_board)
      end

      def add_items(board:, board_builder: BoardBuilder)
        builder = board_builder.new
        yield(builder)
        add_items_to_remote_board(items: builder.items, remote_board: board)
      rescue LocalJumpError
        raise ArgumentError, 'No items where added to the board'
      end

      def get_board(board:)
        request_board(board: board)
      end

      private

      def create_remote_board(board:, remote_board_class: RemoteBoard)
        authorize_if_no_bearer_token!
        response = faraday.post(
          '/v2/boards',
          JSON.pretty_generate(board.to_initial_request_params),
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        remote_board = remote_board_class.new(JSON.parse(response.body, symbolize_names: true))
        board.items.any? ? add_items_to_remote_board(items: board.items, remote_board: remote_board) : remote_board
      end

      def add_items_to_remote_board(items:, remote_board:)
        items.group_by(&:class).each do |_, grouped_items|
          grouped_items.each do |item|
            item.add_to_board(client: self, remote_board: remote_board)
          end
        end
        remote_board
      end

      def request_board(board:, remote_board: RemoteBoard)
        authorize_if_no_bearer_token!
        response = faraday.get(
          "/v2/boards/#{board.id}",
          {},
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        remote_board.new(JSON.parse(response.body, symbolize_names: true))
      end

    end
  end
end
