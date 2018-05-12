require 'spec_helper'

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
    transfer = client.create_transfer(name: 'My amazing board', description: 'Hi there!') do |builder|
      # Upload ourselves
      add_result = builder.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      expect(add_result).to eq(true)

      # Upload ourselves again, but using add_file_at
      add_result = builder.add_file_at(path: __FILE__) # Upload ourselves again, but this time via path
      expect(add_result).to eq(true)

      # Upload the large file
      add_result = builder.add_file(name: 'large.bin', io: very_large_file)
      expect(add_result).to eq(true)

      expect(add_result).to eq(true)
    end

    expect(transfer).to be_kind_of(WeTransferClient::RemoteTransfer)
    expect(transfer.id).to be_kind_of(String)

    # expect(transfer.version_identifier).to be_kind_of(String)
    expect(transfer.state).to be_kind_of(String)
    expect(transfer.name).to eq('My amazing board')
    expect(transfer.description).to eq('Hi there!')
    expect(transfer.items).to be_kind_of(Array)
    expect(transfer.items.length).to eq(3)

    item = transfer.items.first
    expect(item).to be_kind_of(WeTransferClient::RemoteItem)

    expect(transfer.shortened_url).to be_kind_of(String)
    response = Faraday.get(transfer.shortened_url)
    expect(response.status).to eq(302)
    expect(response['location']).to start_with('https://wetransfer')
  end

  it 'is able to create a transfer with no items even if passed a block' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    response = client.create_transfer(name: 'My amazing board', description: 'Hi there!') do |builder|
    end
    expect(response[:size]).to eq(0)
    expect(response[:items]).to eq([])
  end

  it 'is able to create a transfer with no items without a block' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    response = client.create_empty_transfer(name: 'My amazing board', description: 'Hi there!')
    expect(response[:size]).to eq(0)
    expect(response[:items]).to eq([])
  end

  it 'refuses to create a transfer when reading an IO raises an error' do
    broken = StringIO.new('hello')
    def broken.read(*)
      raise 'This failed somehow'
    end

    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    expect(client).not_to receive(:faraday) # Since we will not be doing any requests - we fail earlier
    expect {
      client.create_transfer(name: 'My amazing board', description: 'Hi there!') do |builder|
        builder.add_file(name: 'broken', io: broken)
      end
    }.to raise_error(/failed somehow/)
  end

  it 'refuses to create a transfer when given an IO of 0 size' do
    broken = StringIO.new('')

    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    expect {
      client.create_transfer(name: 'My amazing board', description: 'Hi there!') do |builder|
        builder.add_file(name: 'broken', io: broken)
      end
    }.to raise_error(/has a size of 0/)
  end
end
