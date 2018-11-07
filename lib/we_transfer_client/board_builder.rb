module WeTransfer
  class BoardBuilder
    attr_reader :items
    class TransferIOError < StandardError; end

    def initialize
      @items = []
    end

    def add_file(name:, io:)
      @items << FutureFile.new(name: name, io: io)
    end

    def add_file_at(path:)
      add_file(name: File.basename(path), io: File.open(path, 'rb'))
    end

    def add_web_url(url:, title: url)
      @items << FutureLink.new(url: url, title: title)
    end

  end
end