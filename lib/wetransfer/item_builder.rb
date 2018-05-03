module WeTransfer
  class ItemBuilder
    class FileDoesNotExistError < ArgumentError; end

    def initialize(item: nil)
      @item = if item.nil?
                Item.new
              else
                item
              end
    end

    def path(path:)
      @item.path = path
    end

    def content_identifier
      @item.content_identifier = 'file'
    end

    def local_identifier
      # only take the file name and shorten it to 36 characters if it's longer
      @item.local_identifier = @item.path.split('/').last.gsub(' ', '')[0..35]
    end

    def name
      @item.name = @item.path.split('/').last
    end

    def size
      @item.size = File.size(@item.path)
    end

    def id(item:, id:)
      item.id = id
    end

    def upload_url(item:, url:)
      item.upload_url = [url]
    end

    def multipart_parts(item:, part_count:)
      item.multipart_parts = part_count
    end

    def multipart_id(item:, multi_id:)
      item.multipart_id = multi_id
    end

    def upload_id(item:, upload_id:)
      item.upload_id = upload_id
    end

    def item
      @item
    end

    def validate_file
      raise FileDoesNotExistError, "#{@item} does not exist" unless File.exist?(@item.path)
    end
  end
end
