module WeTransfer
  class ItemBuilder

    def initialize(item: nil)
      if item.nil?
        @item = Item.new
      else
        @item = item
      end
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

    def set_id(item:, id:)
      item.id = id
    end

    def set_upload_url(item:, url: )
      item.upload_url = [url]
    end

    def set_multipart_parts(item:, part_count: )
      item.multipart_parts = part_count
    end

    def set_multipart_id(item:, multi_id:)
      item.multipart_id = multi_id
    end

    def set_upload_id(item:,upload_id:)
      item.upload_id = upload_id
    end


    def item
      @item
    end



    # def update_items(transfer:, items: )
    #   items.each do |item|
    #     item_object = transfer.items.select{|t| t.name == item['name']}.first
    #     item_object.set_id(id: item['id'])
    #     item_object.set_upload_url(url: item['upload_url'] )
    #     item_object.set_multipart_parts(part_count: item['meta']['multipart_parts'] )
    #     item_object.set_multipart_id(multi_id: item['meta']['multipart_upload_id'] )
    #     item_object.set_upload_id(upload_id: item['upload_id'] )
    #   end
    # end
    def validate_file
      raise StandardError, 'File does not exists' if File.exists?(@item.path) == false
    end
  end
end
