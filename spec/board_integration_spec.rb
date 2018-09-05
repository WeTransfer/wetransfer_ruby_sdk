require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransferClient do
  let :test_logger do
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end

  let :very_large_file do
    tf = Tempfile.new('test-upload')
    20.times { tf << Random.new.bytes(1024 * 1024) }
    tf << Random.new.bytes(rand(1..512))
    tf.rewind
    tf
  end

  let :client do
    WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  describe '.add_file_at' do
    it 'should call #add_file' do
      board = client.create_board(name: 'Test board', description: 'A board description') do |b|
        expect(b).to receive(:add_file).with(name: anything, io: kind_of(::IO))

        b.add_file_at(path: __FILE__)
      end
    end

    it 'should accept a file path to be added to a board' do
      board = client.create_board(name: 'test board', description: 'A board description') do |b|
        b.add_file_at(path: __FILE__)
      end
      expect(board.items.count).to be(1)
    end
  end

  it 'should create a empty board with name and description' do
    board = client.create_board(name: 'Test board', description: 'A board description')
    expect(board.name).to eq('Test board')
    expect(board.description).to eq('A board description')
    expect(board.url).to be_kind_of(String)
    expect(board).to be_kind_of(RemoteBoard)
    expect(board.items).to be_empty
  end

  it 'should create a board with only a name' do
    board = client.create_board(name: 'Test board', description: '')
    expect(board.name).to eq('Test board')
    expect(board.url).to be_kind_of(String)
    expect(board).to be_kind_of(RemoteBoard)
  end

  it 'should return an error when board has no name' do
    expect{
      client.create_board(name: '', description: 'test description of board')
    }.to raise_error(WeTransferClient::Error)
  end

  it 'should create a board with one file' do
    board = client.create_board(name: 'Test board', description: 'A board description') do |b|
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
    end
    expect(board.items.first.class).to be(RemoteFile)
    expect(board.items.first.name).to eq(File.basename(__FILE__))
    expect(board.items.first.multipart.id).to_not be_empty
    expect(board.items.count).to eq(1)
  end

  it 'should given an error when file not exists' do
    board = client.create_board(name: 'Test board', description: 'A board description')
    expect{
      client.add_files(board: board) do |b|
        b.add_file_at(path: '/path/to/non/existing/file.jpg')
      end
    }.to raise_error(Errno::ENOENT)
  en

  it 'should create a board with two items' do
    board = client.create_board(name: 'Test board', description: 'A board description') do |b|
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      b.add_file(name: 'large.bin', io: very_large_file)
    end
    expect(board.items.map{|d|d.class}.uniq).to eq([RemoteFile])
    expect(board.items.first.name).to eq(File.basename(__FILE__))
    expect(board.items.first.multipart.id).to_not be_empty
    expect(board.items.last.name).to eq('large.bin')
    expect(board.items.count).to eq(2)
  end

  it 'should give an error when one of the files does not exists' do
    ## Could be changed to accept the first two and raise an error on the third
    board = client.create_board(name: 'Test board', description: 'A board description')
    expect{
      client.add_files(board: board) do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_file(name: 'large.bin', io: very_large_file)
        b.add_file_at(path: '/path/to/non/existing/file.jpg')
      end
    }.to raise_error(Errno::ENOENT)
  end

  it 'should accept adding file to a existing board' do
    board = client.create_board(name: 'Test board', description: 'A board description') do |b|
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
    end
    expect(board.items.count).to eq(1)

    updated_board = client.add_items(board: board) do |b|
      b.add_file(name: 'large_1.bin', io: very_large_file)
      b.add_file(name: 'large_2.bin', io: very_large_file)
    end
    expect(updated_board.items.count).to be(3)
    expect(updated_board.items.map{|d|d.class}.uniq).to eq([RemoteFile])
    expect(updated_board.items.map{|d|d.id}.count).to be(3)
  end

  it 'should create a board with one web_item' do
    skip
  end

  it 'should create a board with a file and web_item' do
    skip
  end

  it 'should create a empty board and accept new file and web_items to be added' do
    skip
  end

  it 'should return a board on request' do
    skip
  end

  it 'should allow manual upload of files to boards' do
    skip
  end

  # it 'should '
end
