module WeTransfer
  class Client
    attr_accessor :api_key, :api_bearer_token
    attr_reader   :api_url, :connection

    # Initializes a new Client object
    #
    # @param options [Hash]
    # @return [WetransferRubySdk::WeTransferClient]
    def initialize(options = {})
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      yield(self) if block_given?
    end

    # Creates a Faraday connection object for use in requests (not very extensible right now)
    #
    # @return [Faraday::Connection]
    def self.connection
      Faraday.new(url: api_url) do |faraday|
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end

    # Convenience method, allows for accessing (and overriding the URL with an envvar if necessary)
    #
    # @return [String]
    def self.api_url
      ENV.fetch('WT_API_URL') { 'https://dev.wetransfer.com' }
    end

    # @return [Hash]
    def credentials
      {
        api_key: api_key,
        api_bearer_token: api_bearer_token
      }
    end

    # @return [Boolean]
    def credentials?
      credentials.values.none? { |v| blank?(v) }
    end

    # @return [Boolean]
    def api_key?
      !blank?(credentials[:api_key])
    end

    # @return [Boolean]
    def api_bearer_token?
      !blank?(credentials[:api_bearer_token])
    end

    private

    def blank?(s)
      s.respond_to?(:empty?) ? s.empty? : !s
    end
  end
end
