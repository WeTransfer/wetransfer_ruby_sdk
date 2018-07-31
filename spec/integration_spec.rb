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

    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.id).to be_kind_of(String)

    # expect(transfer.version_identifier).to be_kind_of(String)
    expect(transfer.state).to be_kind_of(String)
    expect(transfer.name).to eq('My amazing board')
    expect(transfer.description).to eq('Hi there!')
    expect(transfer.items).to be_kind_of(Array)
    expect(transfer.items.length).to eq(3)

    item = transfer.items.first
    expect(item).to be_kind_of(RemoteItem)

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

  it 'is able to create a transfer with only webcontent' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'My collection of web content', description: 'link collection') do |builder|
      10.times do
        builder.add_web_url(url: 'https://www.wetransfer.com')
      end
    end
    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.id).to be_kind_of(String)

    # expect(transfer.version_identifier).to be_kind_of(String)
    expect(transfer.state).to be_kind_of(String)
    expect(transfer.name).to eq('My collection of web content')
    expect(transfer.description).to eq('link collection')
    expect(transfer.items).to be_kind_of(Array)
    expect(transfer.items.length).to eq(10)

    item = transfer.items.first
    expect(item).to be_kind_of(RemoteItem)

    expect(transfer.shortened_url).to be_kind_of(String)
    response = Faraday.get(transfer.shortened_url)
    expect(response.status).to eq(302)
    expect(response['location']).to start_with('https://wetransfer')
  end

  it 'is able to create a transfer with web_content and files' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'Mixed Board Content', description: 'Files and Webcontent') do |builder|
      # Upload ourselves
      add_result = builder.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      expect(add_result).to eq(true)

      # Upload ourselves again, but using add_file_at
      add_result = builder.add_file_at(path: __FILE__) # Upload ourselves again, but this time via path
      expect(add_result).to eq(true)

      # Upload the large file
      add_result = builder.add_file(name: 'large.bin', io: very_large_file)
      expect(add_result).to eq(true)

      # add url to transfer
      add_result = builder.add_web_url(url: 'http://www.wetransfer.com', title: 'website used for file transfers')
      expect(add_result).to eq(true)
    end

    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.id).to be_kind_of(String)

    expect(transfer.state).to be_kind_of(String)
    expect(transfer.name).to eq('Mixed Board Content')
    expect(transfer.description).to eq('Files and Webcontent')
    expect(transfer.items).to be_kind_of(Array)
    expect(transfer.items.length).to eq(4)

    item = transfer.items.first
    expect(item).to be_kind_of(RemoteItem)

    expect(transfer.shortened_url).to be_kind_of(String)
    response = Faraday.get(transfer.shortened_url)
    expect(response.status).to eq(302)
    expect(response['location']).to start_with('https://wetransfer')
  end

  it 'is able to do create a empty transfer to add items later' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'Board', description: 'Test board for functionality')
    expect(transfer.size).to eq(0)
    expect(transfer.items).to eq([])
  end

  it 'add items to a excisting transfer using a block' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'Board', description: 'Test board for functionality')
    expect(transfer.items).to eq([])

    updated_transfer = client.add_items_to(transfer: transfer) do |item|
      item.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      item.add_file_at(path: __FILE__)
      item.add_file(name: 'large.bin', io: very_large_file)
      item.add_web_url(url: 'http://www.wetransfer.com', title: 'website used for file transfers')
    end

    expect(updated_transfer.items.size).to eq(4)
    expect(transfer.shortened_url).to eq(updated_transfer.shortened_url)
    expect(transfer.id).to eq(updated_transfer.id)
    expect(updated_transfer.items[0].content_identifier).to eq('file')
    expect(updated_transfer.items[1].content_identifier).to eq('file')
    expect(updated_transfer.items[2].content_identifier).to eq('file')
    expect(updated_transfer.items[3].content_identifier).to eq('web_content')

    response = Faraday.get(updated_transfer.shortened_url)
    expect(response.status).to eq(302)
    expect(response['location']).to start_with('https://wetransfer')
  end

  it 'should give a error when using add_items_to without block' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'Board', description: 'Test board for functionality')
    expect(transfer.items).to eq([])

    expect {
      client.add_items_to(transfer: transfer)
    }.to raise_error(WeTransferClient::ArgumentError, /No items where added to the transfer/)
  end

  it 'is should support a manual way for uploading files with a block' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'Board', description: 'Test board for functionality', manual_upload: true) do |item|
      item.add_file(name: 'large.bin', io: very_large_file)
    end
    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.items.size).to eq(1)
    expect(transfer.items.first.upload_url).to start_with('https://wetransfer-eu-prod-spaceship')
    expect(transfer.items.first.meta[:multipart_parts]).to eq(4)
    first_item = transfer.items.first

    # Simulation of obtaining upload urls, and uploading chunks

    chunk_size = 6 * 1024 * 1024

    (1..first_item.meta[:multipart_parts]).each do |part_n_one_based|
      response = client.request_item_upload_url(item: first_item, part_number: part_n_one_based)
      upload_url = response.fetch(:upload_url)
      expect(upload_url).to start_with('https://wetransfer-eu-prod-spaceship')
      part_io = StringIO.new(very_large_file.read(chunk_size))
      part_io.rewind
      upload_response = Faraday.put(upload_url, part_io, 'Content-Type' => 'binary/octet-stream', 'Content-Length' => part_io.size.to_s)
      expect(upload_response.status).to eq(200)
    end
    complete_response = client.complete_item!(item_id: first_item.id)
    expect(complete_response[:message]).to match(/File is marked as complete./)
  end

  it 'should support a manual way for uploading files without a block' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'Board', description: 'Test board for functionality', manual_upload: true)

    updated_transfer = client.add_items_to(transfer: transfer, manual_upload: true) do |item|
      item.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      item.add_file_at(path: __FILE__)
      item.add_file(name: 'large.bin', io: very_large_file)
      item.add_web_url(url: 'http://www.wetransfer.com', title: 'website used for file transfers')
    end

    expect(updated_transfer).to be_kind_of(RemoteTransfer)
    expect(updated_transfer.items.size).to eq(4)
    expect(updated_transfer.items.first.upload_url).to start_with('https://wetransfer-eu-prod-spaceship')
    expect(transfer.shortened_url).to be(updated_transfer.shortened_url)

    # Simulation of obtaining upload urls, and uploading chunks

    chunk_size = 6 * 1024 * 1024
    files = [File.open(__FILE__, 'rb'), File.open(__FILE__, 'rb'), very_large_file]
    updated_transfer.items.each_with_index do |item, index|
      next if item.content_identifier == 'web_content'
      (1..item.meta[:multipart_parts]).each do |part_n_one_based|
        response = client.request_item_upload_url(item: item, part_number: part_n_one_based)
        upload_url = response.fetch(:upload_url)

        expect(upload_url).to start_with('https://wetransfer-eu-prod-spaceship')
        part_io = StringIO.new(files[index].read(chunk_size))
        part_io.rewind
        upload_response = Faraday.put(upload_url, part_io, 'Content-Type' => 'binary/octet-stream', 'Content-Length' => part_io.size.to_s)
        expect(upload_response.status).to eq(200)
      end
      complete_response = client.complete_item!(item_id: item.id)
      expect(complete_response[:message]).to match(/File is marked as complete./)
    end
  end
end
