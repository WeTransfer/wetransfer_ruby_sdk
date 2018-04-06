module WeTransfer
  class Client
    attr_accessor :api_key, :api_bearer_token

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
