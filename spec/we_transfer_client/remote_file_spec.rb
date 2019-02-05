require 'spec_helper'

describe WeTransfer::RemoteFile do
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger) }
  # let(:board) { WeTransfer::Board.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__)) }
  let(:transfer) { WeTransfer::Transfer.new(client: client, message: "testTransfer") }

  let(:params) {
    {
      id: SecureRandom.uuid,
      name: 'Board name',
      size: Random.rand(9999999),
      url: nil,
      multipart: {
        part_numbers: Random.rand(10),
        id: SecureRandom.uuid,
        chunk_size: WeTransfer::RemoteBoard::CHUNK_SIZE,
      },
      type: 'file',
      client: client,
      transfer: transfer,
    }
  }

  describe '#initializer' do
    it 'initialized when no url is given' do
      params.delete(:url)
      described_class.new(params)
    end

    it 'initialized when no item is given' do
      params.delete(:items)
      described_class.new(params)
    end

    %i[id size multipart name].each do |required_param|
      it "fails when #{required_param} is missing" do
        params.delete(required_param)
        expect {
          described_class.new(params)
        }.to raise_error ArgumentError, %r(#{required_param})
      end
    end

    it 'must have a struct in multipart' do
      remote_file = described_class.new(params)
      expect(remote_file.multipart).to be_kind_of(Struct)
    end

    it 'multipart has partnumber, id and chunk_size keys' do
      remote_file = described_class.new(params)
      expect(remote_file.multipart.members).to eq(params[:multipart].keys)
    end
  end

  describe '#request_transfer_upload_url' do
    # TODO
  end

  describe '#request_board_upload_url' do
    before do
      skip
      @new_board = WeTransfer::Board.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__))
      @new_board.add_items { |f| f.add_file(name: File.basename(__FILE__), size: File.size(__FILE__)) }
    end
    let(:remote_file) { @new_board.remote_board.items.first }
    let(:fake_remote_file) { WeTransfer::RemoteFile.new(id: SecureRandom.uuid, name: 'Board name', size: Random.rand(9999999), url: nil, multipart: { part_numbers: Random.rand(10), id: SecureRandom.uuid, chunk_size: WeTransfer::RemoteBoard::CHUNK_SIZE, }, type: 'file', client: client) }

    it 'returns a url' do
      response = remote_file.request_board_upload_url(board_id: @new_board.remote_board.id, part_number: 1)
      expect(response).to start_with('https://wetransfer-eu-prod-spaceship')
    end

    it 'raises an error when file is not inside board collection' do
      expect {
        fake_remote_file.request_board_upload_url(board_id: @new_board.remote_board.id, part_number: 1)
      }.to raise_error WeTransfer::Client::Error, /File not found./
    end
  end

  describe '#complete_board_file' do
    before do
      skip
      @new_board = WeTransfer::Board.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__))
      @new_board.add_items { |f| f.add_file(name: File.basename(__FILE__), size: File.size(__FILE__)) }
      @new_board.upload_file!(io: File.open(__FILE__, 'rb'))
    end

    it 'returns a success message on file completion' do
      remote_file = @new_board.remote_board.items.last
      response = remote_file.complete_board_file(board_id: @new_board.remote_board.id)
      expect(response[:success]).to be true
      expect(response[:message]).to eq("File is marked as complete.")
    end
  end

  describe 'getters' do
    let(:subject) { described_class.new(params) }

    %i[multipart name type id url].each do |getter|
      it "responds to #{getter}" do
        subject.send getter
      end
    end
  end
end
