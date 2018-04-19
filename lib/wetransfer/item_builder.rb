module WeTransfer
  class ItemBuilder

    def self.build
      builder = new
      yield(builder)
      builder.item
    end

    def initialize
      @item = Item.new
    end

    def item
      raise 'File does not exists' if File.exists?(@item.path) == false
      @item
    end

    def set_path(path:)
      @item.path = path
    end

    def set_content_identifier
      @item.content_identifier = 'file'
    end

    def set_local_identifier
      # only take the file name and shorten it to 36 characters if exceeding
      @item.local_identifier =  @item.path.split('/').last.gsub(' ', '')[0..36]
    end

    def set_name
      @item.name = @item.path.split('/').last
    end

    def set_size
      @item.size = File.size(@item.path)
    end
  end
end
