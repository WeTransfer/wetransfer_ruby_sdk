require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransferClient do
  let (:params) {
    { api_key: ENV.fetch('WT_API_KEY') }
  }
  let (:client) {
    described_class.new(params)
  }

  it 'exposes VERSION' do
    expect(WeTransferClient::VERSION).to be_kind_of(String)
  end

  describe '#initialize' do
    it 'creates a new instance' do
      client
    end
  end

  describe '#create_transfer' do
    it 'throws an argument error when no message is given' do
      expect{
        client.create_transfer
      }.to raise_error ArgumentError
    end

    it 'creates a empty transfer when no block is given' do
      expect {
        client.create_transfer(message: 'test transfer')
      }.to raise_error ArgumentError
    end

    it 'creates a RemoteTransfer object' do
      transfer = client.create_transfer(message: 'Test Transfer') do |t|
        t.add_file(name: 'test file ', io: File.open(__FILE__, 'rb'))
      end
      expect(transfer).to be_kind_of(RemoteTransfer)
    end

    it 'after created a transfer the url is nil' do
      transfer = client.create_transfer(message: 'Test Transfer') do |t|
        t.add_file(name: 'test file ', io: File.open(__FILE__, 'rb'))
      end
      expect(transfer.url).to be_nil
    end

    it 'after created a transfer the url is nil' do
      transfer = client.create_transfer(message: 'Test Transfer') do |t|
        t.add_file(name: 'test file ', io: File.open(__FILE__, 'rb'))
      end
      expect(transfer.state).to eq('uploading')
    end
  end

  describe '#create_board' do
    it 'throws an Argument error when no name is given' do
      expect{
        client.create_board(description: 'test description')
      }.to raise_error ArgumentError
    end

    it 'throws an Argument error when no description is given' do
      expect{
        client.create_board(name: 'test name')
      }.to raise_error ArgumentError
    end

    it 'Creates a RemoteBoard object' do
      board = client.create_board(name: 'test board', description: 'test description')
      expect(board).to be_kind_of(RemoteBoard)
    end

    it 'Creates a board with no items when no block is passed' do
      board = client.create_board(name: 'test board', description: 'test description')
      expect(board.items).to be_empty
    end
  end
end
