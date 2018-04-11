module WeTransfer
  class Authorizer
    def initialize(client)
      raise ArgumentError, 'Not a WeTransfer client!' if client.class != WeTransfer::Client
      @client = client
    end

    def request_jwt
      response = @client.api_connection.post do |req|
        req.url '/v1/authorize'
        req.headers['X-API-Key'] = @client.api_key
        req.headers['Content-Type'] = 'application/json'
      end

      raise StandardError, 'Authentication Failed' if response.status == 403 || JSON.parse(response.body)['status'] != 'success'
      @client.api_bearer_token = JSON.parse(response.body)['token']
    end
  end
end
