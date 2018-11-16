require 'spec_helper'

describe WeTransfer::Client do
  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
  end

  it 'creates a board, let you add items to it, upload files and complete them' do
    # Initiate a new board
    board = WeTransfer::Board.new(client: client, name: 'Integration Test', description: 'Test the functionality of this SDK')
    expect(board).to be_kind_of(WeTransfer::Board)

    # Add the items to board
    board.add_items do |b|
      b.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
      b.add_web_url(url: 'https://rubygems.org/gems/wetransfer', title: 'WeTransfer Ruby SDK Rubygems')
      b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
      b.add_web_url(url: 'https://github.com/WeTransfer/wetransfer_ruby_sdk', title: 'WeTransfer Ruby SDK GitHub')
      b.add_file_at(path: fixtures_dir + 'Japan-02.jpg')
      b.add_web_url(url: 'https://developers.wetransfer.com/', title: 'WeTransfer Developers Website')
    end

    # Upload all the files by giving the IO of the file
    board.upload_file!(io: File.open(__FILE__, 'rb'))
    board.upload_file!(io: File.open(fixtures_dir + 'Japan-01.jpg', 'rb'))
    board.upload_file!(io: File.open(fixtures_dir + 'Japan-02.jpg', 'rb'))

    # it raises an error when file doens't exists or isn't in the collection
    expect {
      board.upload_file!(io: File.open(fixtures_dir + 'Japan-03.jpg', 'rb'))
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
    expect(board.remote_board.items.count).to be(6)
    expect(board.remote_board.files.count).to be(3)
    expect(board.remote_board.links.count).to be(3)
  end
end
