require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransferClient do
  TWO_CHUNKS_FILE_NAME = 'spec/testdir/two_chunks'

  before(:all) do
    Dir.mkdir('spec/testdir') unless Dir.exist?('spec/testdir')
    unless File.exist?(TWO_CHUNKS_FILE_NAME)
      File.open(TWO_CHUNKS_FILE_NAME, '
        w') do |f|
        f.puts('-' * (described_class::MAGIC_PART_SIZE + 3))
        puts File.absolute_path(f)
      end
    end
  end

  let (:two_chunks) { File.open("#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}", 'r') }

  let (:test_logger) do
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end

  let (:client) do
    WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  it 'creates a transfer with 2 files ' do
    transfer = client.create_transfer(message: 'Test transfer') do |t|
      t.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      t.add_file(name: 'two_chunks', io: two_chunks)
    end
    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.url).to be(nil)
    expect(transfer.files.first.url).to be(nil)
    expect(transfer.state).to eq('uploading')

    client.upload_transfer_file(object: transfer, file: transfer.files[0], io: File.open(__FILE__, 'rb') )
    client.upload_transfer_file(object: transfer, file: transfer.files[1], io: two_chunks )

    # binding.pry
  end


  #   skip
  #   client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  #   transfer = client.create_transfer(name: 'My amazing board', description: 'Hi there!') do |builder|
  #     # Upload ourselves
  #     add_result = builder.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
  #     expect(add_result).to eq(true)

  #     # Upload ourselves again, but using add_file_at
  #     add_result = builder.add_file_at(path: __FILE__) # Upload ourselves again, but this time via path
  #     expect(add_result).to eq(true)

  #     # Upload the large file
  #     add_result = builder.add_file(name: 'large.bin', io: very_large_file)
  #     expect(add_result).to eq(true)

  #     expect(add_result).to eq(true)
  #   end

  #   expect(transfer).to be_kind_of(RemoteTransfer)
  #   expect(transfer.id).to be_kind_of(String)

  #   # expect(transfer.version_identifier).to be_kind_of(String)
  #   expect(transfer.state).to be_kind_of(String)
  #   expect(transfer.name).to eq('My amazing board')
  #   expect(transfer.description).to eq('Hi there!')
  #   expect(transfer.items).to be_kind_of(Array)
  #   expect(transfer.items.length).to eq(3)

  #   item = transfer.items.first
  #   expect(item).to be_kind_of(RemoteItem)

  #   expect(transfer.shortened_url).to be_kind_of(String)
  #   response = Faraday.get(transfer.shortened_url)
  #   expect(response.status).to eq(302)
  #   expect(response['location']).to start_with('https://wetransfer')
  # end

  # it 'is able to create a transfer with no items even if passed a block' do
  #   skip
  #   client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  #   response = client.create_transfer(name: 'My amazing board', description: 'Hi there!') do |builder|
  #   end
  #   expect(response[:size]).to eq(0)
  #   expect(response[:items]).to eq([])
  # end

  # it 'is able to create a transfer with no items without a block' do
  #   skip
  #   client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  #   response = client.create_empty_transfer(name: 'My amazing board', description: 'Hi there!')
  #   expect(response[:size]).to eq(0)
  #   expect(response[:items]).to eq([])
  # end

  # it 'refuses to create a transfer when reading an IO raises an error' do
  #   skip
  #   broken = StringIO.new('hello')
  #   def broken.read(*)
  #     raise 'This failed somehow'
  #   end

  #   client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  #   expect(client).not_to receive(:faraday) # Since we will not be doing any requests - we fail earlier
  #   expect {
  #     client.create_transfer(name: 'My amazing board', description: 'Hi there!') do |builder|
  #       builder.add_file(name: 'broken', io: broken)
  #     end
  #   }.to raise_error(/failed somehow/)
  # end

  # it 'refuses to create a transfer when given an IO of 0 size' do
  #   skip
  #   broken = StringIO.new('')

  #   client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  #   expect {
  #     client.create_transfer(name: 'My amazing board', description: 'Hi there!') do |builder|
  #       builder.add_file(name: 'broken', io: broken)
  #     end
  #   }.to raise_error(/has a size of 0/)
  # end

  # it 'is able to create a transfer with only webcontent' do
  #   skip
  #   client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  #   transfer = client.create_transfer(name: 'My collection of web content', description: 'link collection') do |builder|
  #     10.times do
  #       builder.add_web_url(url: 'https://www.wetransfer.com')
  #     end
  #   end
  #   expect(transfer).to be_kind_of(RemoteTransfer)
  #   expect(transfer.id).to be_kind_of(String)

  #   # expect(transfer.version_identifier).to be_kind_of(String)
  #   expect(transfer.state).to be_kind_of(String)
  #   expect(transfer.name).to eq('My collection of web content')
  #   expect(transfer.description).to eq('link collection')
  #   expect(transfer.items).to be_kind_of(Array)
  #   expect(transfer.items.length).to eq(10)

  #   item = transfer.items.first
  #   expect(item).to be_kind_of(RemoteItem)

  #   expect(transfer.shortened_url).to be_kind_of(String)
  #   response = Faraday.get(transfer.shortened_url)
  #   expect(response.status).to eq(302)
  #   expect(response['location']).to start_with('https://wetransfer')
  # end

  # it 'is able to create a transfer with web_content and files' do
  #   skip
  #   client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  #   transfer = client.create_transfer(name: 'Mixed Board Content', description: 'Files and Webcontent') do |builder|
  #     # Upload ourselves
  #     add_result = builder.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
  #     expect(add_result).to eq(true)

  #     # Upload ourselves again, but using add_file_at
  #     add_result = builder.add_file_at(path: __FILE__) # Upload ourselves again, but this time via path
  #     expect(add_result).to eq(true)

  #     # Upload the large file
  #     add_result = builder.add_file(name: 'large.bin', io: very_large_file)
  #     expect(add_result).to eq(true)

  #     # add url to transfer
  #     add_result = builder.add_web_url(url: 'http://www.wetransfer.com', title: 'website used for file transfers')
  #     expect(add_result).to eq(true)
  #   end

  #   expect(transfer).to be_kind_of(RemoteTransfer)
  #   expect(transfer.id).to be_kind_of(String)

  #   # expect(transfer.version_identifier).to be_kind_of(String)
  #   expect(transfer.state).to be_kind_of(String)
  #   expect(transfer.name).to eq('Mixed Board Content')
  #   expect(transfer.description).to eq('Files and Webcontent')
  #   expect(transfer.items).to be_kind_of(Array)
  #   expect(transfer.items.length).to eq(4)

  #   item = transfer.items.first
  #   expect(item).to be_kind_of(RemoteItem)

  #   expect(transfer.shortened_url).to be_kind_of(String)
  #   response = Faraday.get(transfer.shortened_url)
  #   expect(response.status).to eq(302)
  #   expect(response['location']).to start_with('https://wetransfer')
  # end
end
