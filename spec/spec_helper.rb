require 'simplecov'
require 'securerandom'

SimpleCov.start do
  add_filter '/spec/'
end

require 'we_transfer_client'
require 'pry'
require 'rspec'
require 'bundler'
Bundler.setup
require 'tempfile'
require 'dotenv'
require 'webmock/rspec'
Dotenv.load

module SpecHelpers
  def fixtures_dir
    __dir__ + '/fixtures/'
  end

  def test_logger
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end
end

RSpec.configure do |config|
  config.include SpecHelpers
  config.extend SpecHelpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.default_formatter = 'doc'
  config.order = :random
end
