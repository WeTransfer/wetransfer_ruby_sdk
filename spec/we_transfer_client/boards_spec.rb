require 'spec_helper'

require_relative '../../lib/we_transfer_client.rb'

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
        b.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
        b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
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
        b.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
        b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
        b.add_file_at(path: fixtures_dir + 'Japan-02.jpg')
      end
      expect(board.remote_board.items.count).to eq(4)
      expect(board.remote_board.files.count).to eq(3)
    end

    it 'throws a error when a filename already exists in the board' do
      expect{
        board.add_items do |b|
          b.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
          b.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
        end
      }.to raise_error ArgumentError, 'Duplicate file entry'
    end

    it 'throws a error when a links already exisits in the board' do
      expect{
        board.add_items do |b|
          b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
          b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
        end
      }.to raise_error ArgumentError, 'Duplicate link entry'
    end
  end

  describe '#upload_file!' do
    before do
      board.add_items do |b|
        b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
        b.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
      end
    end

    let(:board) {
      described_class.new(client: client, name: 'Board', description: 'pre-made board')
    }

    it 'after adding links and files the files are uploaded to the board' do
      expect{
        board.upload_file!(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        board.upload_file!(io: File.open(fixtures_dir + 'Japan-01.jpg', 'rb'))
      }.not_to raise_error
    end

    it 'raises a error when io keyword is missing' do
      expect{
        board.upload_file!(name: File.basename(__FILE__))
      }.to raise_error ArgumentError
    end

    it 'returns a error when trying to upload non existing files' do
      expect {
        board.upload_file!(name: 'nowhere.gif', io: File.open('/this/is/a/path/to/nowhere.gif', 'rb'))
      }.to raise_error Errno::ENOENT
    end

    it 'returns an error when file size doenst match' do
      expect {
        board.upload_file!(name: 'Japan-01.jpg', io: File.open(fixtures_dir + 'Japan-02.jpg', 'rb'))
      }.to raise_error WeTransfer::TransferIOError
    end

    it 'uploads a file if name and path are given' do
      expect{
        board.upload_file!(name: 'Japan-01.jpg', io: File.open(fixtures_dir + 'Japan-01.jpg', 'rb'))
      }.not_to raise_error
    end
  end

  describe '#complete_file' do
    before do
      board.add_items do |b|
        b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
        b.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
      end

      board.upload_file!(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      board.upload_file!(io: File.open(fixtures_dir + 'Japan-01.jpg', 'rb'))
    end

    let(:board) {
      described_class.new(client: client, name: 'Board', description: 'pre-made board')
    }

    it 'completes files without raising a error' do
      expect{
        board.complete_file!(name: 'Japan-01.jpg')
        board.complete_file!(name: File.basename(__FILE__))
      }.not_to raise_error
    end

    it 'raises an error when file doenst exists' do
      expect{
        board.complete_file!(name: 'i-do-not-exist.gif')
      }.to raise_error WeTransfer::TransferIOError
    end

    it 'raises an error when file doenst match' do
      expect {
        board.complete_file!(name: 'Japan-02.jpg')
      }.to raise_error WeTransfer::TransferIOError
    end
  end
end
