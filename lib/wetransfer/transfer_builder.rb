module WeTransfer
  class TransferBuilder
    attr_reader :api_connection
    CHUNK_SIZE = 6_291_456

    def self.build
      builder = new
      yield(builder)
      builder.transfer
    end

    def initialize
      @transfer = Transfer.new
    end

    def transfer
      # stuff that could go wrong can be raised here
      @transfer
    end

    def duplicate_client(client:)
      @client = client
    end

    def set_details(name: nil, description: nil)
      @transfer.name = name || "File Transfer: #{Time.now.strftime('%d-%m-%Y')}"
      @transfer.description = description || 'Transfer generated with WeTransfer Ruby SDK'
    end

    def set_items(items:)
      @transfer.build_items(items: items)
    end

    def create_initial_transfer
      response = post_request(path: '/v1/transfers', body: @transfer.transfer_params)
      @transfer.id = response['id']
      set_shortened_url(url: response['shortened_url'])
      update_items(items: response['items'])
    end

    def set_items_upload_url
      @transfer.items.each do |item|
        upload_urls = []
        item.multipart_parts.times do |part|
          part += 1
          response = get_request(path: "/v1/files/#{item.id}/uploads/#{part}/#{item.multipart_id}")
          upload_urls << response['upload_url']
        end
        item.upload_url = upload_urls
      end
    end

    def upload_files
      @transfer.items.each do |item|
        file_object = File.open(item.path)
        item.upload_url.each do |url|
          chunk = file_object.read(CHUNK_SIZE)
          upload(file: chunk, url: url)
        end
      end
    end

    def complete_transfer
      @transfer.items.each do |item|
        post_request(path: "/v1/files/#{item.id}/uploads/complete")
      end
    end

    private

    def set_shortened_url(url: )
      @transfer.shortened_url = url
    end

    def update_items(items: )
      items.each do |item|
        item_object = @transfer.items.select{|t| t.name == item['name']}.first
        set_item_id(item: item_object, id: item['id'])
        set_item_upload_url(item: item_object, url: item['upload_url'] )
        set_item_multipart_parts(item: item_object, part_count: item['meta']['multipart_parts'] )
        set_item_multipart_id(item: item_object, multi_id: item['meta']['multipart_upload_id'] )
        set_item_upload_id(item: item_object, upload_id: item['upload_id'] )
      end
    end

    def upload(file:, url:)
      conn = Faraday.new(url: url) do |faraday|
        faraday.request :multipart
        faraday.adapter :net_http
      end
      conn.put do |req|
        req.headers['Content-Length'] = file.size.to_s
        req.body = file
      end
    end

    def set_item_id(item:, id:)
      item.id = id
    end

    def set_item_upload_url(item:, url: )
      item.upload_url = [url]
    end

    def set_item_multipart_parts(item:, part_count: )
      item.multipart_parts = part_count
    end

    def set_item_multipart_id(item:, multi_id:)
      item.multipart_id = multi_id
    end

    def set_item_upload_id(item:, upload_id:)
      item.upload_id = upload_id
    end

    def post_request(path:, body: nil)
      response = @client.api_connection.post do |req|
        req.url(path)
        request_header_params(req: req)
        req.body = body.to_json
      end
      raise StandardError, response.body if response.status == 401 #unauthorized
      raise StandardError, response.body if response.status == 403 #forbidden
      JSON.parse(response.body)
    end

    # return a json repsonse from the request
    def get_request(path:)
      response = @client.api_connection.get do |req|
        req.url(path)
        request_header_params(req: req)
      end
      raise StandardError, response.body if response.status == 401 #unauthorized
      raise StandardError, response.body if response.status == 403 #forbidden
      JSON.parse(response.body)
    end

    def request_header_params(req:)
      req.headers['X-API-Key'] = @client.api_key
      req.headers['Authorization'] = 'Bearer ' + @client.api_bearer_token
      req.headers['Content-Type'] = 'application/json'
    end
  end
end
