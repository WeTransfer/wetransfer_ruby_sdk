require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransfer::Client do
  before(:all) do
    Dir.mkdir('spec/testdir') unless Dir.exist?('spec/testdir')
    unless File.exist?(TWO_CHUNKS_FILE_NAME)
      File.open(TWO_CHUNKS_FILE_NAME, 'w') do |f|
        f.puts('-' * (PART_SIZE + 3))
        puts File.absolute_path(f)
      end
    end
  end

  let(:two_chunks) { File.open("#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}", 'r') }

  let(:test_logger) do
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end

  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  it 'creates a transfer with 2 files ' do
    # Create a transfer with two Files, one small File and one multipart File
    transfer = client.create_transfer(message: 'Test transfer') do |t|
      t.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      t.add_file(name: 'two_chunks', io: two_chunks)
    end
    expect(transfer).to be_kind_of(RemoteTransfer)

    # The url is nil until the transfer is completed
    expect(transfer.url).to be(nil)
    expect(transfer.files.first.url).to be(nil)
    expect(transfer.state).to eq('uploading')

    client.upload_file(object: transfer, file: transfer.files[0], io: File.open(__FILE__, 'rb'))
    client.upload_file(object: transfer, file: transfer.files[1], io: two_chunks)

    client.complete_file!(object: transfer, file: transfer.files[0])
    client.complete_file!(object: transfer, file: transfer.files[1])

    # Check the Transfer status to be downloadable
    result_id = client.complete_transfer(transfer: transfer).id

    resulting_transfer = loop do
      res = client.get_transfer(transfer_id: result_id)
      break res if res.state != 'processing'
      sleep 1
    end

    expect(resulting_transfer.state).to eq('downloadable')

    response = Faraday.get(resulting_transfer.url)
    # it hits the short-url with redirect
    expect(response.status).to eq(302)
    expect(response['location']).to start_with('https://wetransfer.com/')
  end
end
