module WeTransfer
  class Transfer
    attr_accessor :id, :name, :description, :shortened_url, :items

    def initialize
      @items = []
    end

    def build_items(items:)
      items.each do |item|
        item = ItemBuilder.build do |builder|
          builder.set_path(path: item)
          builder.set_content_identifier
          builder.set_local_identifier
          builder.set_name
          builder.set_size
        end
        self.items.push(item)
      end
    end

    def transfer_params
      { name: name,
        description: description,
        items: items_params
      }
    end

    def items_params
      transfer_items = []
      items.each do |item|
        transfer_items << { local_identifier: item.local_identifier,
                         content_identifier: item.content_identifier,
                         filename: item.name,
                         filesize: item.size
                        }
      end
      transfer_items
    end


  end
end
