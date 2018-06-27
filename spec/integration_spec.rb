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

  it 'is able to create a transfer with only webcontent' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'My collection of web content', description: 'link collection') do |builder|
      10.times do
        builder.add_web_content(path: 'https://www.wetransfer.com')
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
      add_result = builder.add_web_content(path: 'http://www.wetransfer.com')
      expect(add_result).to eq(true)
    end

    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.id).to be_kind_of(String)

    # expect(transfer.version_identifier).to be_kind_of(String)
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

  it 'is able to create a transfer with files from a url' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'Url File collection', description: 'Added a file from url') do |builder|
      # Upload File fromn url
      add_result = builder.add_file_from_url(path: 'https://cdn.wetransfer.net/assets/about/about-whoweare-c0a2e06eec356294412d5abc95aca52e3df669f71c86dbb0c04230b91eba3e18.png' )
      expect(add_result).to eq(true)
    end
    expect(transfer.items.length).to eq(1)
    expect(transfer.shortened_url).to be_kind_of(String)
    response = Faraday.get(transfer.shortened_url)
    expect(response.status).to eq(302)
  end

  it 'supports images from url with jpg extension' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'JPG images', description: 'Images from url') do |builder|
      add_result = builder.add_file_from_url(path: 'https://images.ctfassets.net/5jh3ceokw2vz/2tKtSoutJ6ua6aEaycOK2i/fe2f32c3228d5a60c7b0ee09a3cb6fdb/Jesse_Draxler_2.jpg')
      expect(add_result).to eq(true)
      add_result = builder.add_file_from_url(path: 'https://images.pexels.com/photos/1181655/pexels-photo-1181655.jpeg')
      expect(add_result).to eq(true)
    end
    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.name).to eq('JPG images')
    expect(transfer.description).to eq('Images from url')
    expect(transfer.items).to be_kind_of(Array)
    expect(transfer.items.length).to eq(2)
  end

  it 'supports images from url with gif extension' do
    # although uploading works, the gif is not playing
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'GIF images', description: 'Images from url') do |builder|
      add_result = builder.add_file_from_url(path: 'https://media.giphy.com/media/108RlBCR49SDAc/giphy.gif')
      expect(add_result).to eq(true)
      add_result = builder.add_file_from_url(path: 'https://media.giphy.com/media/11sBLVxNs7v6WA/giphy.gif')
      expect(add_result).to eq(true)
    end
    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.name).to eq('GIF images')
    expect(transfer.description).to eq('Images from url')
    expect(transfer.items).to be_kind_of(Array)
    expect(transfer.items.length).to eq(2)
  end

  it 'supports images from url with png extension' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'PNG images', description: 'Images from url') do |builder|
      add_result = builder.add_file_from_url(path: 'https://cdn.pixabay.com/photo/2017/01/03/02/07/vine-1948358_1280.png')
      expect(add_result).to eq(true)
      add_result = builder.add_file_from_url(path: 'https://cdn.pixabay.com/photo/2017/01/03/02/07/vine-1948358_1280.png')
      expect(add_result).to eq(true)
    end
    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.name).to eq('PNG images')
    expect(transfer.description).to eq('Images from url')
    expect(transfer.items).to be_kind_of(Array)
    expect(transfer.items.length).to eq(2)
  end

  it 'supports images from url with pdf extension' do
    client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
    transfer = client.create_transfer(name: 'PDF images', description: 'Images from url') do |builder|
      add_result = builder.add_file_from_url(path: 'http://www.africau.edu/images/default/sample.pdf')
      expect(add_result).to eq(true)
      add_result = builder.add_file_from_url(path: 'http://www.africau.edu/images/default/sample.pdf')
      expect(add_result).to eq(true)
    end
    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.name).to eq('PDF images')
    expect(transfer.description).to eq('Images from url')
    expect(transfer.items).to be_kind_of(Array)
    expect(transfer.items.length).to eq(2)
  end
end
