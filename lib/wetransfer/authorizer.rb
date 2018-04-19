module WeTransfer
  class Authorizer

    def self.request_jwt(client:)
      response = client.api_connection.post do |req|
        req.url '/v1/authorize'
        req.headers['X-API-Key'] = client.api_key
        req.headers['Content-Type'] = 'application/json'
      end

      raise StandardError, 'Authentication Failed' if response.status == 403
      client.api_bearer_token = JSON.parse(response.body)['token']
    end
  end
end
