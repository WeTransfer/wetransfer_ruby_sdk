module WeTransfer
  class Client
    attr_accessor :api_key
    attr_reader :api_connection
    CHUNK_SIZE = 6_291_456

    # Initializes a new Client object
    def initialize(api_key:)
      @api_key = api_key
      @api_connection ||= WeTransfer::Connection.new(client: self)
    end

    # If you pass in items to the transfer it'll create the transfer with them,
    # otherwise it creates a "blank" transfer.
    def create_transfer(name: nil, description: nil, items: [])
      raise ArgumentError, 'The items field must be an array' unless items.is_a?(Array)
      @transfer = build_transfer_object(name, description).transfer
      items.any? ? create_transfer_with_items(items: items) : create_initial_transfer
      @transfer
    end

    def add_items(transfer: nil, items: [])
      @transfer ||= transfer
      raise ArgumentError, 'No items found' if items.empty?
      raise ArgumentError, 'Transfer object is missing' if @transfer.nil?
      create_transfer_items(items: items)
      send_items_to_transfer
      upload_and_complete_items
      @transfer
    end

    def create_transfer_with_items(items: [])
      raise ArgumentError, 'Items array cannot be empty' if items.empty?
      create_transfer_items(items: items)
      create_initial_transfer
      upload_and_complete_items
    end

    private

    def build_transfer_object(name, description)
      transfer_builder = TransferBuilder.new
      transfer_builder.set_details(name: name, description: description)
      transfer_builder
    end

    def create_transfer_items(items:)
      items.each do |item|
        item_builder = ItemBuilder.new
        item_builder.path(path: item)
        item_builder.content_identifier
        item_builder.local_identifier
        item_builder.name
        item_builder.size
        @transfer.items.push(item_builder.item)
      end
    end

    def create_initial_transfer
      response = @api_connection.post_request(path: '/v1/transfers', body: @transfer.transfer_params)
      TransferBuilder.id(transfer: @transfer, id: response['id'])
      TransferBuilder.shortened_url(transfer: @transfer, url: response['shortened_url'])
      update_item_objects(response_items: response['items']) if response['items'].any?
    end

    def send_items_to_transfer
      response = @api_connection.post_request(path: "/v1/transfers/#{@transfer.id}/items", body: {items: @transfer.items_params})
      update_item_objects(response_items: response)
    end

    def update_item_objects(response_items:)
      response_items.each do |item|
        item_object = @transfer.items.select { |t| t.name == item['name'] }.first
        item_builder = ItemBuilder.new(item: item_object)
        item_builder.id(item: item_object, id: item['id'])
        item_builder.upload_url(item: item_object, url: item['upload_url'])
        item_builder.multipart_parts(item: item_object, part_count: item['meta']['multipart_parts'])
        item_builder.multipart_id(item: item_object, multi_id: item['meta']['multipart_upload_id'])
        item_builder.upload_id(item: item_object, upload_id: item['upload_id'])
        add_item_upload_url(item: item_builder.item) if item_builder.item.multipart_parts > 1
      end
    end

    def add_item_upload_url(item:)
      upload_urls = []
      item.multipart_parts.times do |part|
        part += 1
        response = @api_connection.get_request(path: "/v1/files/#{item.id}/uploads/#{part}/#{item.multipart_id}")
        upload_urls << response['upload_url']
      end
      item.upload_url = upload_urls
    end

    def upload_and_complete_items
      upload_files
      complete_transfer
    end

    def upload_files
      @transfer.items.each do |item|
        file_object = File.open(item.path)
        item.upload_url.each do |url|
          chunk = file_object.read(CHUNK_SIZE)
          @api_connection.upload(file: chunk, url: url)
        end
      end
    end

    def complete_transfer
      @transfer.items.each do |item|
        @api_connection.post_request(path: "/v1/files/#{item.id}/uploads/complete")
      end
    end
  end
end
