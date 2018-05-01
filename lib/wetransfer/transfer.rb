module WeTransfer
  class Transfer
    attr_accessor :id, :name, :description, :shortened_url, :items

    def initialize
      @items = []
    end

    def transfer_params
      {
        name: name,
        description: description,
        items: items_params
      }
    end

    def items_params
      transfer_items = []
      items.each do |item|
        transfer_items << {
          local_identifier: item.local_identifier,
          content_identifier: item.content_identifier,
          filename: item.name,
          filesize: item.size
        }
      end
      transfer_items
    end
  end
end
