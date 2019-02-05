module WeTransfer
  class CommunicationError < StandardError; end
  module CommunicationHelper
    API_URI_BASE = 'https://dev.wetransfer.com'.freeze

    # private

    def request_as
      authorize_if_no_bearer_token!

      @request_as ||= Faraday.new(API_URI_BASE) do |c|
        c.response :logger, @client.logger
        c.adapter Faraday.default_adapter
        c.headers = auth_headers.merge(
          "User-Agent" => "WetransferRubySdk/#{WeTransfer::VERSION} Ruby #{RUBY_VERSION}",
          "Content-Type" => "application/json",
        )
      end
    end

    private

    def auth_headers
      authorize_if_no_bearer_token!

      {
        'X-API-Key' => @client.api_key,
        'Authorization' => ('Bearer %s' % @bearer_token),
      }
    end

    def ensure_ok_status!(response)
      case response.status
      when 200..299
        true
      when 400..499
        @client.logger.error response
        raise WeTransfer::CommunicationError, JSON.parse(response.body)["message"]
      when 500..504
        @client.logger.error response
        raise WeTransfer::CommunicationError, "Response had a #{response.status} code, we could retry"
      else
        @client.logger.error response
        raise WeTransfer::CommunicationError, "Response had a #{response.status} code, no idea what to do with that"
      end
    end

    private

    def authorize_if_no_bearer_token!
      return @bearer_token if @bearer_token

      response = Faraday.new(API_URI_BASE) do |c|
        c.response :logger, @client.logger
        c.adapter Faraday.default_adapter
        c.headers = {
          "User-Agent" => "WetransferRubySdk/#{WeTransfer::VERSION} Ruby #{RUBY_VERSION}",
          "Content-Type" => "application/json",
        }
      end.post(
        '/v2/authorize',
        '',
        'Content-Type' => 'application/json',
        'X-API-Key' => @client.api_key,
      )
      ensure_ok_status!(response)
      bearer_token = JSON.parse(response.body)['token']
      if bearer_token.nil? || bearer_token.empty?
        raise WeTransfer::CommunicationError, "The authorization call returned #{response.body} and no usable :token key could be found there"
      end
      @bearer_token = bearer_token
    end
  end
end
