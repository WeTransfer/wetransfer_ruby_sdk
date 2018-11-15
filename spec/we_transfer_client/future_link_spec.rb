require 'spec_helper'

describe WeTransfer::FutureLink do
  let(:params) { { url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal', client: client } }
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:board) { WeTransfer::Boards.new(client: client, name: 'future_file_spec.rb', description: 'this test the behaviour of the future_file') }
  let(:link) { described_class.new(params) }
  let(:fake_remote_board) {
    WeTransfer::RemoteBoard.new(
      id: SecureRandom.uuid,
      state: 'downloadable',
      url: 'http://wt.tl/123abcd',
      name: 'RemoteBoard',
      description: 'Test Description',
      success: true,
      client: client
    )
  }

  describe '#initializer' do
    it 'needs a :url keyword arg' do
      params.delete(:url)
      expect {
        described_class.new(params)
      }.to raise_error(ArgumentError, /url/)
    end

    it 'takes url when no title is given' do
      params.delete(:title)
      expect(described_class.new(params).title).to be(params.fetch(:url))
    end

    it 'succeeds if given all arguments' do
      described_class.new(params)
    end

    it 'raises a error when input cant be converted to string' do
      expect {
        described_class.new(url: 'https://www.developers.wetransfer.com', title: 12354, client: client)
      }.to raise_error NoMethodError, /undefined method `to_str'/
    end

    it 'raises a error when nil passed as argument' do
      expect {
        described_class.new(url: nil, title: 12354, client: client)
      }.to raise_error NoMethodError, /undefined method `to_str'/
    end
  end

  describe '#to_request_params' do
    it 'creates params properly' do
      as_params = described_class.new(params).to_request_params

      expect(as_params[:url]).to eq('https://www.developers.wetransfer.com')
      expect(as_params[:title]).to be_kind_of(String)
    end

    it 'contains url and title keys' do
      as_params = described_class.new(params).to_request_params
      expect(as_params.keys).to include(:url, :title)
    end
  end

  describe '#add_to_board' do
    it 'add future link to a remote_board and return a RemoteLink' do
      response = link.add_to_board(remote_board: board.remote_board)
      expect(response).to be_kind_of(WeTransfer::RemoteLink)
    end

    it 'raises an error when board doenst exists' do
      expect {
        link.add_to_board(remote_board: fake_remote_board)
      }.to raise_error WeTransfer::Client::Error, /This board does not exist/
    end

    it 'adds the item to the remote board' do
      response_link = link.add_to_board(remote_board: board.remote_board)
      expect(board.remote_board.items).to include(response_link)
    end
  end

  describe 'getters' do
    let(:subject) { described_class.new(params) }

    %i[url title].each do |getter|
      it "responds to #{getter}" do
        subject.send getter
      end
    end
  end
end
