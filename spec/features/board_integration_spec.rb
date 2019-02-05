require 'spec_helper'

describe WeTransfer::Client do
  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end
  let(:small_file_1_location) { fixtures_dir + 'small_file.1.txt' }
  let(:small_file_2_location) { fixtures_dir + 'small_file.2.txt' }

  it 'creates a board, let you add items to it, upload files and complete them' do
    WtVCR.laserdisc do
      board = WeTransfer::Board.new(client: client, name: 'Integration Test', description: 'Test the functionality of this SDK')
      expect(board).to be_kind_of(WeTransfer::Board)

      board.add_items do |b|
        b.add_web_url(url: 'https://rubygems.org/gems/wetransfer', title: 'WeTransfer Ruby SDK Rubygems')
        b.add_file_at(path: small_file_1_location)
        b.add_web_url(url: 'https://github.com/WeTransfer/wetransfer_ruby_sdk', title: 'WeTransfer Ruby SDK GitHub')
        b.add_file_at(path: small_file_2_location)
        b.add_web_url(url: 'https://developers.wetransfer.com/', title: 'WeTransfer Developers Website')
      end

      board.upload_file!(io: File.open(small_file_1_location, 'rb'))
      board.upload_file!(io: File.open(small_file_2_location, 'rb'))

      # it raises an error when file doesn't exist or isn't in the collection
      expect {
        board.upload_file!(
          io: File.open(fixtures_dir + 'this-file-does-not-exist-in-your-system.txt', 'rb')
        )
      }.to raise_error Errno::ENOENT

      # After uploading, the files need to be completed
      board.remote_board.files.each do |file|
        board.complete_file!(name: file.name)
      end

      # after completing the board should be completed and accesible
      response = Faraday.get(board.remote_board.url)

      # that should redirect us...
      expect(response.status).to eq(302)
      # ... to a board in the wetransfer domain
      expect(response['location']).to start_with('https://boards.wetransfer')

      expect(board.remote_board.state).to eq('downloadable')
      expect(board.remote_board.items.count).to be(5)
      expect(board.remote_board.files.count).to be(2)
      expect(board.remote_board.links.count).to be(3)
    end
  end
end
