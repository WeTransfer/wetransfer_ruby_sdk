module WeTransfer
  class Client
    attr_accessor :api_key, :api_bearer_token
    attr_reader :api_url, :api_connection

    # Initializes a new Client object
    #
    # @param options [Hash]
    # @return [WeTransfer::Client]
    def initialize(api_key:, api_bearer_token: nil)
      @api_key = api_key
      @api_bearer_token = api_bearer_token
      @api_url = ENV.fetch('WT_API_URL') { 'https://dev.wetransfer.com' }
      @api_connection = create_api_connection_object!
      WeTransfer::Authorizer.request_jwt(client: self)
    end

    # Creates a Faraday connection object for use in requests (not very extensible right now)
    #
    # @return [Faraday::Connection]
    def create_api_connection_object!
      conn = Faraday.new(url: @api_url) do |faraday|
        # faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
      conn
    end

    # @return [Boolean]
    def api_key?
      !blank?(@api_key)
    end

    # @return [Boolean]
    def api_bearer_token?
      !blank?(@api_bearer_token)
    end

    private

    def blank?(s)
      s.respond_to?(:empty?) ? s.empty? : !s
    end
  end
end
