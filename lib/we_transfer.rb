# frozen_string_literal: true

require 'faraday'
require 'logger'
require 'json'
require 'ks'

%w[
  logging
  communication
  client
  transfer
  mini_io
  we_transfer_file
  remote_file version
].each do |file|
  require_relative "we_transfer/#{file}"
end

module WeTransfer
  NULL_LOGGER = Logger.new(nil)

  def self.logger
    @logger || NULL_LOGGER
  end

  # Set the logger to your preferred logger
  #
  # @params new_logger [Logger] the logger that WeTransfer SDK should use
  #
  # example:
  # WeTransfer.logger = Rails.logger
  def self.logger=(new_logger)
    @logger = new_logger
  end
end
