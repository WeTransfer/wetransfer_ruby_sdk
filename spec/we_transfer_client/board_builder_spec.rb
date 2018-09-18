require 'spec_helper'

describe BoardBuilder do
  let (:board) { described_class.new }

  describe '#initialize' do
    it 'initializes with an empty array' do
      expect(board.items.empty?).to be(true)
    end
  end

  describe '#add_file' do
    it 'returns an error when name is missing' do
      expect {
        board.add_file(io: File.open(__FILE__, 'rb'))
      }.to raise_error ArgumentError, /name/
    end

    it 'returns an error when io is missing' do
      expect {
        board.add_file(name: 'file name')
      }.to raise_error ArgumentError, /io/
    end

    it 'returns a error when file doesnt exists' do
      expect {
        board.add_file(name: 'file name', io: File.open('foo', 'rb'))
      }.to raise_error Errno::ENOENT
    end

    it 'adds a file when name and io is given' do
      board.add_file(name: 'file name', io: File.open(__FILE__, 'rb'))
      expect(board.items.first).to be_kind_of(FutureFile)
    end
  end

  describe '#add_file_at' do
    it 'adds a file from a path' do
      board.add_file_at(path: __FILE__)
      expect(board.items.first).to be_kind_of(FutureFile)
    end

    it 'throws a Error when file doesnt exists' do
      expect {
        board.add_file_at(path: '/this/path/leads/to/nothing.exe')
      }.to raise_error Errno::ENOENT
    end

    it 'should call #add_file' do
      client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'))
      board = client.create_board(name: 'Test board', description: 'A board description') do |b|
        expect(b).to receive(:add_file).with(name: anything, io: kind_of(::IO))

        b.add_file_at(path: __FILE__)
      end
    end
  end

  describe '#add_web_url' do
    it 'adds a item to board when url and title are given' do
      board.add_web_url(url: 'http://www.wetransfer.com', title: 'wetransfer')
      expect(board.items.first).to be_kind_of(FutureLink)
    end
  end
end
