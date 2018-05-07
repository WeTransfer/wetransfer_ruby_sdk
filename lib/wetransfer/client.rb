module WeTransfer
  class Client
    attr_accessor :api_key
    attr_reader :api_connection
    CHUNK_SIZE = 6_291_456

    # Initializes a new Client object
    def initialize(api_key:)
      @api_path = ENV.fetch('WT_API_CONNECTION_PATH') { '' }
      @api_key = api_key
      @api_bearer_token ||= request_jwt
      @api_connection ||= WeTransfer::Connection.new(client: self, api_bearer_token: @api_bearer_token)
    end

    def request_jwt
      # Create a connection request without a bearer token for authorization
      # since authorization is what you need to do to retrieve the token.
      auth_connection = WeTransfer::Connection.new(client: self)
      auth_connection.authorization_request
    end

    # If you pass in items to the transfer it'll create the transfer with them,
    # otherwise it creates a "blank" transfer object. You can also leave off the
    # name and description, and it will be auto-generated.
    def create_transfer(name: nil, description: nil, items: [])
      raise ArgumentError, 'The items field must be an array' unless items.is_a?(Array)
      @transfer = build_transfer_object(name, description).transfer
      items.any? ? create_transfer_with_items(items: items) : create_initial_transfer
      @transfer
    end

    # Once you've created a "blank" transfer you can use this to add items to it.
    # Items must have the structure defined in the README, otherwise information will be auto-generated for them.
    def add_items(transfer:, items:)
      @transfer ||= transfer
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
      transfer_builder.name_description(name: name, description: description)
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
      response = @api_connection.post_request(path: '/transfers', body: @transfer.transfer_params)
      TransferBuilder.id(transfer: @transfer, id: response['id'])
      TransferBuilder.shortened_url(transfer: @transfer, url: response['shortened_url'])
      update_item_objects(response_items: response['items']) if response['items'].any?
    end

    def send_items_to_transfer
      response = @api_connection.post_request(path: "/transfers/#{@transfer.id}/items", body: {items: @transfer.items_params})
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
        response = @api_connection.get_request(path: "/files/#{item.id}/uploads/#{part}/#{item.multipart_id}")
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
        file_object.close
      end
    end

    def complete_transfer
      @transfer.items.each do |item|
        @api_connection.post_request(path: "/files/#{item.id}/uploads/complete")
      end
    end
  end
end
