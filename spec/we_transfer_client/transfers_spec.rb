require 'spec_helper'

describe WeTransfer::Client::Transfers do
  describe '#create_transfer_and_upload_files' do
    it 'creates a transfer and uploads the files' do
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      transfer = client.create_transfer_and_upload_files(message: 'test description') do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_file_at(path: "#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}")
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
  end

  pending '#create_transfers'
  pending "#complete_transfer"
  pending "#get_transfer"
end
