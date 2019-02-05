require 'spec_helper'

describe WeTransfer::Board do
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY', logger: test_logger)) }

  describe '#create_board' do
    it 'creates a board' do
      WtVCR.laserdisc do
        WeTransfer::Board.new(client: client, name: 'board test', description: 'Test the functionality of the SDK')
      end
    end

    it 'raises a error when client is not passed' do
      WtVCR.laserdisc do
        expect {
          WeTransfer::Board.new(name: 'board_test', description: 'Test the functionality of the SDK')
        }.to raise_error ArgumentError, /missing keyword: client/
      end
    end

    it 'raises an error when board name is nil' do
      WtVCR.laserdisc do
        expect {
          WeTransfer::Board.new(client: client, name: nil, description: 'Test the functionality of the SDK')
        }.to raise_error WeTransfer::Client::Error
      end
    end

    it 'raises an error when board name is nil' do
      WtVCR.laserdisc do
        expect {
          WeTransfer::Board.new(client: client, name: '', description: 'Test the functionality of the SDK')
        }.to raise_error WeTransfer::Client::Error
      end
    end

    it 'raises an error when board name is a empty string' do
      WtVCR.laserdisc do
        expect {
          WeTransfer::Board.new(client: client, name: '', description: 'Test the functionality of the SDK')
        }.to raise_error WeTransfer::Client::Error
      end
    end

    it 'creates a board without description' do
      WtVCR.laserdisc do
        WeTransfer::Board.new(client: client, name: 'board_test')
      end
    end
  end
end
