require 'simplecov'
require 'securerandom'

SimpleCov.start do
  add_filter '/spec/'
end

require 'we_transfer'
require 'pry'
require 'rspec'
require 'bundler'
Bundler.setup
require 'tempfile'
require 'dotenv'
require 'webmock/rspec'
Dotenv.load

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.default_formatter = 'doc'
  config.order = :random
end

RSpec::Mocks.configuration.verify_partial_doubles = true

WeTransfer.logger = Logger.new(STDOUT)
