require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransfer::Client do
  TWO_CHUNKS_FILE_NAME = 'spec/testdir/two_chunks'

  before(:all) do
    Dir.mkdir('spec/testdir') unless Dir.exist?('spec/testdir')
    unless File.exist?(TWO_CHUNKS_FILE_NAME)
      File.open(
        TWO_CHUNKS_FILE_NAME, '
        w') do |f|
        f.puts('-' * (described_class::MAGIC_PART_SIZE + 3))
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
    transfer = client.create_transfer(message: 'Test transfer') do |t|
      t.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      t.add_file(name: 'two_chunks', io: two_chunks)
    end
    expect(transfer).to be_kind_of(RemoteTransfer)
    expect(transfer.url).to be(nil)
    expect(transfer.files.first.url).to be(nil)
    expect(transfer.state).to eq('uploading')

    client.upload_file(object: transfer, file: transfer.files[0], io: File.open(__FILE__, 'rb'))
    client.upload_file(object: transfer, file: transfer.files[1], io: two_chunks)

    client.complete_file!(object: transfer, file: transfer.files[0])
    client.complete_file!(object: transfer, file: transfer.files[1])

    transfer = client.complete_transfer(transfer: transfer)
    if transfer.state == 'processing'
      sleep 30
      transfer = client.get_transfer(transfer_id: transfer.id)
      expect(transfer.state).to eq('downloadable')
    end
    expect(transfer.state).to eq('downloadable')

    response = Faraday.get(transfer.url)
    # it hits the short-url with redirect
    expect(response.status).to eq(302)
    # but check in the header for a wetransfer domain location
    expect(response['location']).to start_with('https://wetransfer')
    # transfer = client.get_transfer(transfer_id: transfer.id)
  end
end
