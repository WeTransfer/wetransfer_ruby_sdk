module WeTransfer
  class Transfers
    attr_accessor :transfer

    CHUNK_SIZE = 6_291_456

    def initialize(client)
      raise ArgumentError, 'Not a WeTransfer client!' if client.class != WeTransfer::Client
      @client = client
      @transfer = nil
    end


    def create_transfer(name:, description:, items: [])
      request_body = {
        name: name,
        description: description,
        items: items
      }
      response = @client.api_connection.post do |req|
        req.url '/api/v1/transfers'
        req.headers['X-API-Key'] = @client.api_key
        req.headers['Authorization'] = 'Bearer ' + @client.api_bearer_token
        req.headers['Content-Type'] = 'application/json'
        req.body = request_body.to_json
      end

      # Need to raise the right Error Class
      raise StandardError, response.body if response.status == 401 #unauthorized
      raise StandardError, response.body if response.status == 403 #forbidden

      api_response = JSON.parse(response.body)
      raise StandardError, api_response['message'] if api_response['success'] == false
      @transfer = Transfer.new(id: api_response['id'],
        name: name,
        description: description,
        shortened_url: api_response['shortened_url'],
        items: api_response['items'])
    end

    def add_items(transfer:, items:[])
      request_body = {
        items: items
      }

      response = @client.api_connection.post do |req|
        req.url "/api/v1/transfers/#{transfer.id}/items"
        req.headers['X-API-Key'] = @client.api_key
        req.headers['Authorization'] = 'Bearer ' + @client.api_bearer_token
        req.headers['Content-Type'] = 'application/json'
        req.body = request_body.to_json
      end

      api_response = JSON.parse(response.body)
      transfer.items.push(*api_response)
      return transfer
    end

    def get_upload_urls(transfer: )
      transfer.items.each do |item|
        if item['meta']['multipart_parts'] > 1
          upload_urls = []
          item['meta']['multipart_parts'].times do |part|
            part += 1
            response = @client.api_connection.get do |req|
              req.url "/api/v1/files/#{item['id']}/uploads/#{part}/#{item['meta']['multipart_upload_id']}"
              req.headers['X-API-Key'] = @client.api_key
              req.headers['Authorization'] = 'Bearer ' + @client.api_bearer_token
              req.headers['Content-Type'] = 'application/json'
            end
            api_response = JSON.parse(response.body)
            upload_urls << api_response['upload_url']
          end
          item['upload_url'] = upload_urls
        end
      end
      return transfer
    end

    def multi_part_file(item:, file:)
      file_object = File.open(file)
      item['upload_url'].each do |url|
        chunk = file_object.read(CHUNK_SIZE)
        upload_file(file: chunk, url: url)
      end
      complete_file(item: item)
    end

    def single_part_file(item:, file:)
      file_object = File.open(file)
      upload_file(file: file_object, url: item['upload_url'])
      complete_file(item: item)
    end

    private

    def complete_file(item:)
      resp = @client.api_connection.post do |req|
        req.url "/api/v1/files/#{item['id']}/uploads/complete"
        req.headers['X-API-Key'] = @client.api_key
        req.headers['Authorization'] = 'Bearer ' + @client.api_bearer_token
        req.headers['Content-Type'] = 'application/json'
      end
    end

    def upload_file(file:, url:)
      conn = Faraday.new(url: url) do |faraday|
        faraday.request :multipart
        faraday.adapter :net_http
      end
      conn.put do |req|
        req.headers['Content-Length'] = file.size.to_s
        req.body = file
      end
    end
  end

end
