module WeTransfer
  class BoardBuilder < TransferBuilder
    # TRANSFER_XOR_BOARD_PRESENT_ERROR =
    #   "#{name} should be initialized with either a :board or a :transfer kw param".freeze

    attr_reader :links

    def initialize(board:, transfer: nil, **_args)
      raise WeTransfer::Client::Error, TRANSFER_XOR_BOARD_PRESENT_ERROR unless transfer.nil? ^ board.nil?
      super

      @board = board
      @links = []
    end

    def items
      (files + links).flatten
    end

    def add_web_url(url:, title: url)
      @links << FutureLink.new(url: url, title: title, client: @client)
    end

    def select_file_on_name(name:)
      file = files.select { |f| f.name == name }.first
      return file if file
      raise WeTransfer::TransferIOError, 'File not found'
    end
  end
end
