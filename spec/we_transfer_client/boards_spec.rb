require 'spec_helper'

require_relative '../../lib/we_transfer_client.rb'

describe WeTransfer::Client::Boards do
  before do
    skip 'new implementation'
  end

  describe "experimental features" do
    before do
      skip "this interface is still experimental"
    end

    describe '#create_board' do
      it 'creates a board' do
        client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
        board = client.create_board(name: 'test', description: 'test description')
        expect(board).to be_kind_of(RemoteBoard)
      end
    end

    describe "#add_items" do
      it 'adds items to an existing board' do
        client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
        board = client.create_board(name: 'test', description: 'test description')
        updated_board = client.add_items(board: board) do |b|
          b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
          b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
        end
        expect(updated_board).to be_kind_of(RemoteBoard)
        expect(updated_board.items.size).to eq(2)
        expect(updated_board.items.map(&:class)).to eq([RemoteFile, RemoteLink])
      end
    end

    describe "#get_board" do
      it 'gets board' do
        client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
        board = client.create_board(name: 'test', description: 'test description')
        board_request = client.get_board(board: board)

        expect(board_request).to be_kind_of(RemoteBoard)
      end
    end
  end
end

describe WeTransfer::Boards do
  let (:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }

  describe 'Initialize' do
    it 'creates a empty board ' do
      expect(described_class.new(client: client, name: 'New Board', description: 'This is the description')).to be_kind_of(WeTransfer::Boards)
    end

    it 'has client, future and remote board as instance_variable' do
      expect(described_class.new(client: client, name: 'New Board', description: 'This is the description').instance_variables).to include(:@client, :@future_board, :@remote_board)
    end

    it 'creates a board and uploads the files' do
      board = described_class.new(client: client, name: 'test', description: 'test description') do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
      end
      expect(board.remote_board).to be_kind_of(WeTransfer::RemoteBoard)
      expect(board.future_board).to be_kind_of(WeTransfer::FutureBoard)
      expect(board.url).to start_with('https://we.tl/')
      expect(board.remote_board.state).to eq('downloadable')
    end
  end
end
