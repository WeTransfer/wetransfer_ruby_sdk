module WeTransfer
  class Connection

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
      raise StandardError, response.body if response.status == 401 #unauthorized
      raise StandardError, response.body if response.status == 403 #forbidden
      JSON.parse(response.body)
    end

    # return a json repsonse from the request
    def get_request(path:)
      response = @api_connection.get do |req|
        req.url(path)
        request_header_params(req: req)
      end
      raise StandardError, response.body if response.status == 401 #unauthorized
      raise StandardError, response.body if response.status == 403 #forbidden
      JSON.parse(response.body)
    end

    def request_header_params(req:)
      req.headers['X-API-Key'] = @api_key
      req.headers['Authorization'] = 'Bearer ' + @api_bearer_token unless @api_bearer_token.nil?
      req.headers['Content-Type'] = 'application/json'
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
      #catch all non resp.status == 200 responses
      binding.pry unless resp.status == 200
    end

    private

     # Creates a Faraday connection object for use in requests (not very extensible right now)
    #
    # @return [Faraday::Connection]
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
  end
end