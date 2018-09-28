require 'spec_helper'

describe WeTransfer::Client::Boards do
  let(:big_file) { File.open('spec/files/Japan-01.jpg', 'r') }

  let(:test_logger) do
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end

  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end
  describe '#create_board' do
    it 'creates a remote board' do
      client.create_board(name: 'Test Board', description: 'Test Descritpion')
    end

    it 'creates a board with items' do
      client.create_board(name: 'Test Board', description: 'Test descrition') do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_file(name: 'big file', io: big_file)
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
