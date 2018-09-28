require 'spec_helper'

require_relative '../../lib/we_transfer_client.rb'

describe WeTransfer::Client::Boards do
  describe '#create_board_and_upload_files' do
    it 'creates a board and uploads the files' do
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      board = client.create_board_and_upload_files(name: 'test', description: 'test description') do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
      end
      expect(board).to be_kind_of(RemoteBoard)
      expect(board.url).to start_with('https://we.tl/')
      expect(board.state).to eq('downloadable')
    end
  end
  
  describe '#create_board' do
    it 'creates a board' do
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      board = client.create_board(name: 'test', description: 'test description')
      expect(board).to be_kind_of(RemoteBoard)
    end
  end

  describe "#add_items" do
    it 'adds items to a created board' do
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
