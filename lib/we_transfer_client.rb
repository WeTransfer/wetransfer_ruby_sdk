require 'faraday'
require 'logger'
require 'json'

require_relative 'we_transfer_client/version'
require_relative 'we_transfer_client/transfer_builder'
require_relative 'we_transfer_client/board_builder'
require_relative 'we_transfer_client/future_file'
require_relative 'we_transfer_client/future_link'
require_relative 'we_transfer_client/future_transfer'
require_relative 'we_transfer_client/future_board'
require_relative 'we_transfer_client/remote_transfer'
require_relative 'we_transfer_client/remote_board'
require_relative 'we_transfer_client/remote_link'
require_relative 'we_transfer_client/remote_file'
require_relative 'we_transfer_client/transfers'
require_relative 'we_transfer_client/boards'

module WeTransfer
  class Client
    class Error < StandardError; end

    NULL_LOGGER = Logger.new(nil)

    def initialize(api_key:, logger: NULL_LOGGER)
      @api_url_base = 'https://dev.wetransfer.com'
      @api_key = api_key.to_str
      @bearer_token = nil
      @logger = logger
    end

    def faraday
      Faraday.new(@api_url_base) do |c|
        c.response :logger, @logger
        c.adapter Faraday.default_adapter
        c.headers = { 'User-Agent' => "WetransferRubySdk/#{WeTransfer::VERSION} Ruby #{RUBY_VERSION}"}
      end
    end

    def authorize_if_no_bearer_token!
      return if @bearer_token
      response = faraday.post('/v2/authorize', '{}', 'Content-Type' => 'application/json', 'X-API-Key' => @api_key)
      ensure_ok_status!(response)
      @bearer_token = JSON.parse(response.body, symbolize_names: true)[:token]
      if @bearer_token.nil? || @bearer_token.empty?
        raise Error, "The authorization call returned #{response.body} and no usable :token key could be found there"
      end
    end

    def auth_headers
      raise 'No bearer token retrieved yet' unless @bearer_token
      {
        'X-API-Key' => @api_key,
        'Authorization' => ('Bearer %s' % @bearer_token),
      }
    end

    def ensure_ok_status!(response)
      case response.status
      when 200..299
        true
      when 400..499
        @logger.error response
        raise Error, JSON.parse(response.body, symbolize_names: true)[:message]
      when 500..504
        @logger.error response
        raise Error, "Response had a #{response.status} code, we could retry"
      else
        @logger.error response
        raise Error, "Response had a #{response.status} code, no idea what to do with that"
      end
    end
  end
end
