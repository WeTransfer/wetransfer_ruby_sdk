require 'spec_helper'

require_relative '../../lib/we_transfer_client.rb'

describe WeTransfer::Client::Boards do
  before(:all) do
    Dir.mkdir('spec/testdir') unless Dir.exist?('spec/testdir')
    unless File.exist?(TWO_CHUNKS_FILE_NAME)
      File.open(TWO_CHUNKS_FILE_NAME, 'w') do |f|
        f.puts('-' * (PART_SIZE + 3))
        puts File.absolute_path(f)
      end
    end
  end

  let(:two_chunks) { File.open("#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}", 'r') }

  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
  end

  let(:board) do
    client.create_board(name: 'Test Board', description: 'Test Descritpion')
  end

  describe '#add_items' do
    it 'adds items to a board' do
      client.add_items(board: board) do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_file_at(path: "#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}")
        b.add_web_url(url: 'http://www.google.com', title: 'google')
      end
    end

    it 'fails when no block is given' do
      expect {
        client.add_items(board: board)
      }.to raise_error ArgumentError, /No items/
    end

    it 'fails when no board is passed as keyword argument' do
      expect {
        client.add_items do |b|
          b.add_file_at(path: "#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}")
        end
      }.to raise_error ArgumentError, /board/
    end

    it 'fails when file is not found' do
      expect {
        client.add_items(board: board) do |b|
          b.add_file(name: 'file_not_found.rb', io: File.open('path/to/file.rb', 'r'))
        end
      }.to raise_error Errno::ENOENT, /No such file/
    end

    it 'fails when board is not a existing remote board' do
      new_board = RemoteBoard.new(id: 123456, state: 'proccessing', url: 'https://www.we.tl/123456', name: 'fake board')
      expect {
        client.add_items(board: new_board) do |b|
          b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
          b.add_file_at(path: "#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}")
          b.add_web_url(url: 'http://www.google.com', title: 'google')
        end
      }.to raise_error WeTransfer::Client::Error, /404 code/
    end
  end
end
