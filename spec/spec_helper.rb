require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'wetransfer'
require 'pry'
require 'rspec'
require_relative 'test_server'

RSpec.configure do |config|
  config.before :suite do
    TestServer.start(nil)
    ENV['WT_API_URL'] = 'http://localhost:9001'
    ENV['WT_API_CONNECTION_PATH'] = '/v1'
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
