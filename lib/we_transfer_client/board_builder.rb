module WeTransfer
  class BoardBuilder
    attr_reader :files, :links

    def initialize(client:)
      @client = client
      @files = []
      @links = []
    end

    def items
      (@files + @links).flatten
    end

    def add_file(name:, size:)
      @files << FutureFile.new(name: name, size: size, client: @client)
    end

    def add_file_at(path:)
      add_file(name: File.basename(path), size: File.size(path))
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
