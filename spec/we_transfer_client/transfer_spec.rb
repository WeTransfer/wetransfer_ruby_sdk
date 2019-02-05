require 'spec_helper'

describe WeTransfer::Transfer do
  let!(:authentication_stub) {
    stub_request(:post, "#{described_class::API_URI_BASE}/v2/authorize")
      .to_return(status: 200, body: {token: 'test-token'}.to_json, headers: {})
  }

  describe '#create_transfer_and_upload_files' do
    before do
      skip
    end
    it 'creates a transfer and uploads the files' do
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      transfer = client.create_transfer_and_upload_files(message: 'test description') do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
      end

      expect(transfer).to be_kind_of(RemoteTransfer)
      expect(transfer.url).to start_with('https://we.tl/')

      transfer = loop do
        res = client.get_transfer(transfer_id: transfer.id)
        break res if res.state != 'processing'
        sleep 1
      end

      expect(transfer.state).to eq('downloadable')
    end

    it 'fails when no files are added' do
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      expect {
        client.create_transfer_and_upload_files(message: 'test description')
      }.to raise_error ArgumentError, /No files/
    end

    it 'fails with duplicate file names' do
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      expect {
        client.create_transfer_and_upload_files(message: 'All the (same) Things') do |builder|
          builder.add_file(name: 'README.txt', io: StringIO.new("A thing"))
          builder.add_file(name: 'README.txt', io: StringIO.new("another thing"))
        end
      }.to raise_error ArgumentError, /Duplicate file entry/
    end
  end

  describe "#create_transfer" do
    let(:transfer_params) { { client: client, message: 'TestMessage' } }
    let(:client)          { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }

    it "creates a transfer with an id" do
      create_transfer_stub = stub_request(:post, "#{described_class::API_URI_BASE}/v2/transfers").
      to_return(
        status: 200,
        body: {
          id: "fake-id",
          state: "test",
          url: "we.tl/t-12345",
          message: "TestMessage",
          files: [
            name: "small", size: 2, id: "fake-file-id", multipart: { 1 => 2 }
          ],
        }.to_json,
        headers: {}
      )

      transfer = WeTransfer::Transfer.new(transfer_params)

      expect(transfer.id).to be_nil

      transfer.create_transfer do |builder|
        builder.add_file(name: 'small', size: 2)
      end

      expect(create_transfer_stub).to have_been_requested
      expect(transfer.id).to eq "fake-id"
    end

    it "needs a message" do
      expect { WeTransfer::Transfer.new(client: client) }
      .to raise_error ArgumentError, %r(missing keyword: message)
    end

    it "needs at least 1 file" do
      transfer = WeTransfer::Transfer.new(transfer_params)
      expect { transfer.create_transfer }
        .to raise_error ArgumentError, %r(No files were added)
    end
  end

  describe "#finalize!" do
    let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }

    it "hits the `finalize` endpoint" do
      finalize_stub = stub_request(:put, "#{described_class::API_URI_BASE}/v2/transfers/fakeTransfer/finalize")
      .to_return(
        status: 200,
        body: {
          id: "fakeTransfer",
          state: "uploading",
          url: "we.tl/t-21243",
          message: 'testMessage'
        }.to_json,
        headers: {}
      )

      transfer = WeTransfer::Transfer.new(client: client, message: "TestMessage")

      expect(transfer)
        .to receive(:id)
        .and_return('fakeTransfer')

      transfer.finalize!

      expect(finalize_stub).to have_been_requested
    end
  end

  describe "#files" do
    before { skip "Still experimental" }

    it "works?" do
      create_transfer_stub = stub_request(:post, "#{described_class::API_URI_BASE}/v2/transfers").
      to_return(
        status: 200,
        body: {
          id: "fake-id",
          state: "test",
          url: "we.tl/t-12345",
          message: "TestMessage",
          files: [
            name: "small", size: 2, id: "fake-file-id", multipart: { 1 => 2 }
          ],
        }.to_json,
        headers: {}
      )

      # WebMock.allow_net_connect!

      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      transfer = WeTransfer::Transfer.new(client: client, message: 'TestMessage')
      transfer.create_transfer do |builder|
        builder.add_file(name: 'small', size: 2)
      end

      # binding.pry
      transfer.files
      # end
    end
  end

  pending "#finalize_transfer"
  pending "#get_transfer"
end
