module WeTransfer
  class TransferBuilder
    attr_reader :files
    TRANSFER_XOR_BOARD_PRESENT_ERROR =
      "#{name} should be initialized with either a :board or a :transfer kw param".freeze

    def initialize(transfer:, board: nil)
      raise WeTransfer::Client::Error, TRANSFER_XOR_BOARD_PRESENT_ERROR unless transfer.nil? ^ board.nil?

      @transfer = transfer
      @files = []
    end

    def add_file(name:, size:)
      #TODO: Future file should receive a target, not an @transfer (an/or @board)
      @files << FutureFile.new(name: name, size: size, transfer: @transfer)
    end

    def add_file_at(path:)
      add_file(name: File.basename(path), size: File.size(path))
    end
  end
end
