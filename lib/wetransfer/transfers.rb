module WeTransfer
  class Transfers
    attr_accessor :transfer

    def initialize(client)
      raise ArgumentError, 'Not a WeTransfer client!' if client.class != WeTransfer::Client
      @client = client
      @transfer = nil
    end

    def create_new_transfer(name:, description:, items: [])
      request_body = {
        name: name,
        description: description,
        items: items
      }

      response = @client.api_connection.post do |req|
        req.url '/v1/transfers'
        req.headers['X-API-Key'] = @client.api_key
        req.headers['Content-Type'] = 'application/json'
        req.body = request_body.to_json
      end

      api_response = JSON.parse(response.body)
      @transfer = Transfer.new(id: api_response['id'], name: name, description: description, shortened_url: api_response['shortened_url'], items: api_response['items'])
    end
  end
end
