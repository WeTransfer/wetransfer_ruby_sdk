module WeTransfer
  class Connection
    attr_reader :api_connection, :api_bearer_token, :api_key, :api_path

    def initialize(client:, api_bearer_token: '')
      @api_url = ENV.fetch('WT_API_URL') { 'https://dev.wetransfer.com' }
      @api_key = client.api_key
      @api_connection ||= create_api_connection_object!
      @api_bearer_token = api_bearer_token
      @api_path = ENV.fetch('WT_API_CONNECTION_PATH') { '' }
    end

    def authorization_request
      response = @api_connection.post do |req|
        req.url("#{@api_path}/authorize")
        request_header_params(req: req)
      end
      response_validation!(response: response)
      response['token']
    end

    def post_request(path:, body: nil)
      response = @api_connection.post do |req|
        req.url(@api_path + path)
        request_header_params(req: req)
        req.body = body.to_json unless body.nil?
      end
      response_validation!(response: response)
      JSON.parse(response.body)
    end

    def get_request(path:)
      response = @api_connection.get do |req|
        req.url(@api_path + path)
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

    # If you need extra logging for your requests, switch it on by setting WT_API_LOGGING_ON in your .env file.
    def create_api_connection_object!
      conn = Faraday.new(url: @api_url) do |faraday|
        faraday.response :logger if ENV.fetch('WT_API_LOGGING_ON') { nil } # log requests to STDOUT if ENVVAR is present
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
      conn
    end

    def response_validation!(response:)
      raise StandardError, response.reason_phrase if response.status == 401
      raise StandardError, response.reason_phrase if response.status == 403
    end
  end
end
