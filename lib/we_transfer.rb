# frozen_string_literal: true

require 'faraday'
require 'logger'
require 'json'
require 'ks'

%w[communication client transfer mini_io we_transfer_file remote_file version].each do |file|
  require_relative "we_transfer/#{file}"
end

module WeTransfer; end
