require 'spec_helper'

describe WeTransfer::Client::Boards do
  describe '#create_board_and_upload_files' do
    it 'creates a board and uploads the files' do
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      board = client.create_board_and_upload_files(name: 'test', description: 'test description') do |b|
        b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
        b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
      end
      expect(board).to be_kind_of(RemoteBoard)
      expect(board.url).to start_with('https://we.tl/')
      expect(board.state).to eq('downloadable')


    end
  end

  pending '#create_board'
  pending "#add_items"
  pending "#get_board"
end
