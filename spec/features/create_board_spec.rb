require 'spec_helper'

describe WeTransfer::Board do
  let(:big_file_location) { (fixtures_dir + 'Japan-01.jpg') }
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:board) do
    WeTransfer::Board.new(client: client, name: File.basename(__FILE__), description: 'Test the functionality of the SDK')
  end

  describe '#create_board' do
    it 'creates a board' do
      WeTransfer::Board.new(client: client, name: File.basename(__FILE__), description: 'Test the functionality of the SDK')
    end

    it 'raises a error when client is not passed' do
      expect {
        WeTransfer::Board.new(name: File.basename(__FILE__), description: 'Test the functionality of the SDK')
      }.to raise_error ArgumentError, /missing keyword: client/
    end

    it 'raises an error when board name is nil' do
      expect {
        WeTransfer::Board.new(client: client, name: nil, description: 'Test the functionality of the SDK')
      }.to raise_error WeTransfer::Client::Error
    end

    it 'raises an error when board name is nil' do
      expect {
        WeTransfer::Board.new(client: client, name: '', description: 'Test the functionality of the SDK')
      }.to raise_error WeTransfer::Client::Error
    end

    it 'raises an error when board name is a empty string' do
      expect {
        WeTransfer::Board.new(client: client, name: '', description: 'Test the functionality of the SDK')
      }.to WeTransfer::Client::Error
    end

    it 'creates a board without description' do
      WeTransfer::Board.new(client: client, name: File.basename(__FILE__))
    end
  end
end
