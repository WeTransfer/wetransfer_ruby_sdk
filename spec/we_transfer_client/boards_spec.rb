require 'spec_helper'

require_relative '../../lib/we_transfer_client.rb'

# describe WeTransfer::Client::Boards do
#   before do
#     skip 'new implementation'
#   end

#   describe "experimental features" do
#     before do
#       skip "this interface is still experimental"
#     end

#     describe '#create_board' do
#       it 'creates a board' do
#         client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
#         board = client.create_board(name: 'test', description: 'test description')
#         expect(board).to be_kind_of(RemoteBoard)
#       end
#     end

#     describe "#add_items" do
#       it 'adds items to an existing board' do
#         client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
#         board = client.create_board(name: 'test', description: 'test description')
#         updated_board = client.add_items(board: board) do |b|
#           b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
#           b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
#         end
#         expect(updated_board).to be_kind_of(RemoteBoard)
#         expect(updated_board.items.size).to eq(2)
#         expect(updated_board.items.map(&:class)).to eq([RemoteFile, RemoteLink])
#       end
#     end

#     describe "#get_board" do
#       it 'gets board' do
#         client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
#         board = client.create_board(name: 'test', description: 'test description')
#         board_request = client.get_board(board: board)

#         expect(board_request).to be_kind_of(RemoteBoard)
#       end
#     end
#   end
# end

describe WeTransfer::Boards do
  let (:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }

  describe 'Initialize' do
    it 'creates a empty board ' do
      expect(described_class.new(client: client, name: 'New Board', description: 'This is the description')).to be_kind_of(WeTransfer::Boards)
    end

    it 'has client, future and remote board as instance_variable' do
      expect(described_class.new(client: client, name: 'New Board', description: 'This is the description').instance_variables).to include(:@client, :@remote_board)
    end

    it 'creates a board and uploads the files' do
      board = described_class.new(client: client, name: 'test', description: 'test description')
      board.add_items do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
      end
      expect(board.remote_board).to be_kind_of(WeTransfer::RemoteBoard)
      expect(board.remote_board.url).to start_with('https://we.tl/')
      expect(board.remote_board.state).to eq('downloadable')
    end
  end

  describe '#add_items' do
    let (:board) {
      described_class.new(client: client, name: 'Board', description: 'pre-made board')
    }

    it 'adds items to a remote board' do
      board.add_items do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
        b.add_file_at(path: fixtures_dir + 'Japan-02.jpg')
      end
      expect(board.remote_board.items.count).to eq(4)
      expect(board.remote_board.files.count).to eq(3)
    end

    it 'throws a error when a filename already exists in the board' do
      expect{
        board.add_items do |b|
          b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
          b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        end
      }.to raise_error ArgumentError, 'Duplicate file entry'
    end

    it 'throws a error when a links already exisits in the board' do
      expect{
        board.add_items do |b|
          b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
          b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
        end
      }.to raise_error ArgumentError, 'Duplicate link entry'
    end
  end

  describe '#upload_file!' do
    before do
      board.add_items do |b|
        b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
      end
    end

    let(:board) {
      described_class.new(client: client, name: 'Board', description: 'pre-made board')
    }

    it 'after adding links and files the files are uploaded to the board' do
      expect{
        board.upload_file!(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        board.upload_file!(path: fixtures_dir + 'Japan-01.jpg')
      }.not_to raise_error
    end

    it 'returns a error when trying to upload non existing files' do
      expect {
        board.upload_file!(path: '/this/is/a/path/to/nowhere.gif')
      }.to raise_error Errno::ENOENT
    end

    it 'returns an error when file size doenst match' do
      expect {
        board.upload_file!(name: 'Japan-01.jpg', io: File.open(fixtures_dir + 'Japan-02.jpg', 'rb'))
      }.to raise_error WeTransfer::TransferIOError
    end

    it 'uploads a file if name and path are given' do
      expect{
        board.upload_file!(name: 'Japan-01.jpg', path: fixtures_dir + 'Japan-01.jpg')
      }.not_to raise_error
    end
  end

  describe '#complete_file'do
    before do
      board.add_items do |b|
        b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
      end
      board.upload_file!(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      board.upload_file!(path: fixtures_dir + 'Japan-01.jpg')
    end

    let(:board) {
      described_class.new(client: client, name: 'Board', description: 'pre-made board')
    }

    it 'completes files without raising a error' do
      expect{
        board.complete_file!(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        board.complete_file!(path: fixtures_dir + 'Japan-01.jpg')
      }.not_to raise_error
    end

    it 'raises an error when file doenst exists' do
      expect{
        board.complete_file!(path: '/this/is/a/path/to/nowhere.gif')
      }.to raise_error Errno::ENOENT
    end

    it 'raises an error when file doenst match' do
      expect {
        board.complete_file!(name: 'Japan-01.jpg', io: File.open(fixtures_dir + 'Japan-02.jpg', 'rb'))
      }.to raise_error WeTransfer::TransferIOError
    end


  end
end
