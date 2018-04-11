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

module SpecHelpers
  def fixtures_dir
    __dir__ + '/fixtures/'
  end
end

RSpec.configure do |config|
  config.include SpecHelpers
  config.extend SpecHelpers # makes fixtures_dir available for example groups too
  config.before :suite do
    TestServer.start(nil)
    ENV['WT_API_URL'] = 'http://localhost:9001'
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
