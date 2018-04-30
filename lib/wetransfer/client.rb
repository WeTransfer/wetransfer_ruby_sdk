module WeTransfer
  class Client
    attr_accessor :api_key
    # attr_accessor :api_bearer_token
    # attr_reader :api_url, :api_connection
    CHUNK_SIZE = 6_291_456

    # Initializes a new Client object
    #
    # @param options [Hash]
    # @return [WeTransfer::Client]
    def initialize(api_key:)
      @api_key = api_key
      @api_connection ||= WeTransfer::Connection.new(client: self)
    end

    # @return [Boolean]
    def api_connection?
      !blank?(@api_connection)
    end

    # create a new transfer based of the information the client sends
    #
    #
    # return with a transfer object
    def create_transfer(name: nil, description: nil, items: [])
      raise StandardError, 'Not an Array' unless items.is_a?(Array)
      transfer_builder = TransferBuilder.new
      transfer_builder.set_details(name: name, description: description)
      @transfer = transfer_builder.transfer
      create_transfer_items(items: items) if items.any?
      create_initial_transfer
      handle_file_items if items.any?
      return @transfer
    end

    def add_items(transfer: nil, items: [])
      @transfer ||= transfer
      raise StandardError, 'No items found' if items.empty?
      raise StandardError, 'Transfer object is missing' if @transfer.nil?
      create_transfer_items(items: items)
      send_items_to_transfer
      handle_file_items
      return @transfer
    end

    # @return [Boolean]
    def api_key?
      !blank?(@api_key)
    end

    private

    def create_transfer_items(items:)
      items.each do |item|
        item_builder = ItemBuilder.new
        item_builder.set_path(path: item)
        item_builder.set_content_identifier
        item_builder.set_local_identifier
        item_builder.set_name
        item_builder.set_size
        @transfer.items.push(item_builder.item)
      end
    end

    def create_initial_transfer
      response = @api_connection.post_request(path: '/v1/transfers', body: @transfer.transfer_params)
      TransferBuilder.set_id(transfer: @transfer, id: response['id'])
      TransferBuilder.set_shortened_url(transfer: @transfer, url: response['shortened_url'])
      update_item_objects(response_items: response['items']) if response['items'].any?
    end

    def send_items_to_transfer
      response = @api_connection.post_request(path: "/v1/transfers/#{@transfer.id}/items", body: {items: @transfer.items_params})
      update_item_objects(response_items: response)
    end

    def update_item_objects(response_items:)
      response_items.each do |item|
        item_object = @transfer.items.select{|t| t.name == item['name']}.first
        item_builder = ItemBuilder.new(item: item_object)
        item_builder.set_id(item: item_object, id: item['id'])
        item_builder.set_upload_url(item: item_object, url: item['upload_url'])
        item_builder.set_multipart_parts(item: item_object, part_count: item['meta']['multipart_parts'])
        item_builder.set_multipart_id(item: item_object, multi_id: item['meta']['multipart_upload_id'])
        item_builder.set_upload_id(item: item_object, upload_id: item['upload_id'])
        set_item_upload_url(item: item_builder.item) if item_builder.item.multipart_parts > 1
      end
    end

    def set_item_upload_url(item:)
      upload_urls = []
      item.multipart_parts.times do |part|
        part += 1
        response = @api_connection.get_request(path: "/v1/files/#{item.id}/uploads/#{part}/#{item.multipart_id}")
        upload_urls << response['upload_url']
      end
      item.upload_url = upload_urls
    end

    def handle_file_items
      upload_files
      complete_transfer
    end

    def upload_files
      @transfer.items.each do |item|
        file_object = File.open(item.path)
        item.upload_url.each do |url|
          chunk = file_object.read(CHUNK_SIZE)
          res = @api_connection.upload(file: chunk, url: url)
        end
      end
    end

    def complete_transfer
      @transfer.items.each do |item|
        @api_connection.post_request(path: "/v1/files/#{item.id}/uploads/complete")
      end
    end


    def blank?(s)
      s.respond_to?(:empty?) ? s.empty? : !s
    end

  end
end
