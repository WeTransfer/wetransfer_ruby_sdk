require 'spec_helper'

describe WeTransfer::Board do
  # let(:test_logger) { Logger.new(nil) }

  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY', logger: test_logger)) }
  let(:board) do
    WeTransfer::Board.new(client: client, name: File.basename(__FILE__), description: 'Test the functionality of the SDK')
  end

  describe '#add_items' do
    it 'adds items to a board' do
      board.add_items do |b|
        b.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
        b.add_file_at(path: fixtures_dir + 'Japan-02.jpg')
        b.add_web_url(url: 'http://www.google.com', title: 'google')
      end

      board.add_items do |b|
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
        b.add_web_url(url: 'https://developers.wetransfer.com', title: 'developers portal')
      end
    end

    it 'fails when no block is given' do
      expect {
        board.add_items
      }.to raise_error ArgumentError, /No items/
    end

    it 'fails when file is not found' do
      expect {
        board.add_items do |b|
          b.add_file(name: 'file_not_found.rb', size: File.size('/path/to/non-existent-file.rb'))
        end
      }.to raise_error Errno::ENOENT, /No such file/
    end

    it 'fails when file name is missing' do
      expect {
        board.add_items do |b|
          b.add_file(name: '', size: 13)
        end
      }.to raise_error WeTransfer::Client::Error
    end
  end
end
