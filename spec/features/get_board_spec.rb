require 'spec_helper'

describe WeTransfer::Client::Boards do
  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  let(:board) do
    client.create_board(name: 'Test Board', description: 'Test Descritpion')
  end

  describe '#get_board' do
    it 'it gets a exisiting board' do
      client.get_board(board: board)
    end

    it 'fails when no board is given' do
      expect {
        client.get_board
      }.to raise_error ArgumentError, /board/
    end

    it 'fails when board doenst exists' do
      new_board = RemoteBoard.new(id: 123456, state: 'proccessing', url: 'https://www.we.tl/123456', name: 'fake board')
      expect {
        client.get_board(board: new_board)
      }.to raise_error WeTransfer::Client::Error, /404 code/
    end
  end
end
