module WeTransfer
  class TransferBuilder
    attr_reader :files

    def initialize(client:)
      @client = client
      @files = []
    end

    def add_file(name:, size:)
      @files << FutureFile.new(name: name, size: size, client: @client)
    end

    def add_file_at(path:)
      add_file(name: File.basename(path), size: File.size(path))
    end
  end
end
