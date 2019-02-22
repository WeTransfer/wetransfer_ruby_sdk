# frozen_string_literal: true

require 'faraday'
require 'logger'
require 'json'
require 'ks'

%w[communication_helper transfer mini_io we_transfer_file remote_file version].each do |file|
  require_relative "we_transfer/#{file}"
end

module WeTransfer
  class Client
    class Error < StandardError; end
    include CommunicationHelper

    NullLogger = Logger.new(nil)

    attr_reader :transfer

    # Initialize a WeTransfer::Client
    #
    # @param api_key [String] The API key you want to authenticate with
    # @param logger [Logger] (NullLogger) your custom logger
    #
    # @return [WeTransfer::Client]
    def initialize(api_key:, logger: NullLogger)
      CommunicationHelper.reset_authentication!
      CommunicationHelper.api_key = api_key
      CommunicationHelper.logger = logger
    end

    def create_transfer(**args, &block)
      transfer = WeTransfer::Transfer.new(args)
      transfer.persist(&block)
      @transfer = transfer

      self
    end

    def find_transfer(transfer_id)
      @transfer = WeTransfer::Transfer.find(transfer_id)
    end
  end
end
