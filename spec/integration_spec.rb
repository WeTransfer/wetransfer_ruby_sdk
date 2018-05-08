require 'tempfile'
require 'bundler'
Bundler.setup

require 'dotenv'
Dotenv.load

require_relative '../lib/we_transfer_client.rb'

describe WeTransferClient do
  let :test_logger do
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end

  let :very_large_file do
    tf = Tempfile.new('test-upload')
    20.times { tf << Random.new.bytes(1024 * 1024) }
    tf << Random.new.bytes(rand(1..512))
    tf.rewind
    tf
  end

  it 'exposes VERSION' do
    expect(WeTransferClient::VERSION).to be_kind_of(String)
  end

  it 'is able to create a transfer start to finish, both with small and large files' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(title: 'My amazing board', message: 'Hi there!') do |builder|
      # Upload ourselves
      add_result = builder.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      expect(add_result).to eq(true)

      # Upload ourselves again, but using add_file_at
      add_result = builder.add_file_at(path: __FILE__) # Upload ourselves again, but this time via path
      expect(add_result).to eq(true)

      # Upload the large file
      add_result = builder.add_file(name: 'large.bin', io: very_large_file)
      expect(add_result).to eq(true)
    end

    expect(transfer.id).to be_kind_of(String)

    # expect(transfer.version_identifier).to be_kind_of(String)
    expect(transfer.state).to be_kind_of(String)
    expect(transfer.name).to eq('My amazing board')
    expect(transfer.description).to eq('Hi there!')
    expect(transfer.items).to be_kind_of(Array)

    expect(transfer.shortened_url).to be_kind_of(String)
    response = Faraday.get(transfer.shortened_url)
    expect(response.status).to eq(302)
    expect(response['location']).to start_with('https://wetransfer')
  end

  it 'refuses to create a transfer with no items'
  it 'refuses to create a transfer when reading an IO raises an error'
  it 'refuses to create a transfer when given an IO of 0 size'
end
