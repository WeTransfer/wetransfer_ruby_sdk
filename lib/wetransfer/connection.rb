module WeTransfer
  class Connection
    attr_reader :api_connection, :api_bearer_token, :api_key

    def initialize(client:)
      @api_url = ENV.fetch('WT_API_URL') { 'https://dev.wetransfer.com' }
      @api_key = client.api_key
      @api_connection = create_api_connection_object!
      @api_bearer_token ||= request_jwt
    end

    def post_request(path:, body: nil)
      response = @api_connection.post do |req|
        req.url(path)
        request_header_params(req: req)
        req.body = body.to_json unless body.nil?
      end
      response_validation!(response: response)
      JSON.parse(response.body)
    end

    def get_request(path:)
      response = @api_connection.get do |req|
        req.url(path)
        request_header_params(req: req)
      end
      response_validation!(response: response)
      JSON.parse(response.body)
    end

     def upload(file:, url:)
      conn = Faraday.new(url: url) do |faraday|
        faraday.request :multipart
        faraday.adapter :net_http
      end
      resp = conn.put do |req|
        req.headers['Content-Length'] = file.size.to_s
        req.body = file
      end
      response_validation!(response: resp)
    end

    private

    def request_header_params(req:)
      req.headers['X-API-Key'] = @api_key
      req.headers['Authorization'] = 'Bearer ' + @api_bearer_token unless @api_bearer_token.nil?
      req.headers['Content-Type'] = 'application/json'
    end

    def create_api_connection_object!
      conn = Faraday.new(url: @api_url) do |faraday|
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
      conn
    end

    def request_jwt
      response = post_request(path: '/v1/authorize')
      response['token']
    end

    def response_validation!(response:)
      raise StandardError, response.reason_phrase if response.status == 401 #unauthorized
      # raise {status: 401, body: 'You are not Authorized to do this request'} if response.status == 401 #unauthorized
      raise StandardError, response.reason_phrase if response.status == 403 #forbidden
      # raise {status: 403, body: ''This request is forbidden on this domain'} if response.status == 403 #forbidden
    end
  end
end