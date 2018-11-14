require 'spec_helper'

describe WeTransfer::RemoteFile do
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:board) { WeTransfer::Boards.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__)) }

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
    }}

  describe '#initializer' do
    it 'initialized when no url is given' do
      params.delete(:url)
      described_class.new(params)
    end

    it 'initialized when no item is given' do
      params.delete(:items)
      described_class.new(params)
    end

    it 'fails when id is missing' do
      params.delete(:id)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /id/
    end

    it 'fails when state is missing' do
      params.delete(:size)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /size/
    end

    it 'fails when url is missing' do
      params.delete(:multipart)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /multipart/
    end

    it 'fails when name is missing' do
      params.delete(:name)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /name/
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
      @new_board = WeTransfer::Boards.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__))
      @new_board.add_items { |f| f.add_file(name: File.basename(__FILE__), size: File.size(__FILE__)) }
    end
    let(:remote_file) { @new_board.remote_board.items.first }
    let(:fake_remote_file) { WeTransfer::RemoteFile.new(id: SecureRandom.uuid, name: 'Board name', size: Random.rand(9999999), url: nil, multipart: { part_numbers: Random.rand(10), id: SecureRandom.uuid, chunk_size: WeTransfer::RemoteBoard::CHUNK_SIZE, }, type: 'file',) }

    it 'returns a url' do
      response = remote_file.request_board_upload_url(client: client, board_id: @new_board.remote_board.id, part_number: 1)
      expect(response).to start_with('https://wetransfer-eu-prod-spaceship')
    end

    it 'raises an error when file is not inside board collection' do
      expect {
        fake_remote_file.request_board_upload_url(client: client, board_id: @new_board.remote_board.id, part_number: 1)
      }.to raise_error WeTransfer::Client::Error, /File not found./
    end
  end

  describe '#complete_board_file' do
    before do
      @new_board = WeTransfer::Boards.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__))
      @new_board.add_items { |f| f.add_file(name: File.basename(__FILE__), size: File.size(__FILE__)) }
      @new_board.upload_file!(io: File.open(__FILE__, 'rb'))
    end

    it 'returns a success message on file completion' do
      remote_file = @new_board.remote_board.items.last
      response = remote_file.complete_board_file(client: client, board_id: @new_board.remote_board.id)
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
