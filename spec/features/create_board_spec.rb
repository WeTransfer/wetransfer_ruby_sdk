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
  describe '#create_board' do
    it 'creates a remote board' do
      client.create_board(name: 'Test Board', description: 'Test Descritpion')
    end

    it 'creates a board with items' do
      client.create_board(name: 'Test Board', description: 'Test descrition') do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_file(name: 'two_chunks', io: two_chunks)
        b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
      end
    end

    it 'fails when name is missing' do
      expect {
        client.create_board(name: '', description: 'Test Descritpion')
      }.to raise_error WeTransfer::Client::Error, /400 code/
    end

    it 'fails when file path is wrong' do
      expect {
        client.create_board(name: 'Test Board', description: 'Test descrition') do |b|
          b.add_file(name: 'file_not_found.rb', io: File.open('path/to/file.rb', 'r'))
        end
      }.to raise_error Errno::ENOENT, /No such file/
    end

    it 'fails when file name is missing' do
      expect {
        client.create_board(name: 'Test Board', description: 'Test descrition') do |b|
          b.add_file(name: '', io: File.open(__FILE__, 'rb'))
        end
      }.to raise_error WeTransfer::Client::Error, /400 code/
    end
  end
end
