require 'faraday'
require 'logger'
require 'json'

require_relative 'we_transfer_client/version'
require_relative 'we_transfer_client/communication_helper'
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
require_relative 'we_transfer_client/transfer'
require_relative 'we_transfer_client/board'
require_relative 'we_transfer_client/debug_faraday'

module WeTransfer
  class TransferIOError < StandardError; end
  class Client
    attr_reader :api_key, :logger

    class Error < StandardError; end

    NULL_LOGGER = Logger.new(nil)

    def initialize(api_key:, logger: NULL_LOGGER)
      @api_key = api_key.to_str
      @logger = logger
    end

    def get_transfer(transfer_id:)
      @transfer = WeTransfer::Transfer.get_transfer(args.merge(client: self))
    end
  end
end
