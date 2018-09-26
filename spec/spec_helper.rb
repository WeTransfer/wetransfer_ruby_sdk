require 'simplecov'
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
Dotenv.load

TWO_CHUNKS_FILE_NAME = 'spec/testdir/two_chunks'
PART_SIZE = 6 * 1024 * 1024

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
