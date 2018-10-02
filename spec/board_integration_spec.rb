require 'spec_helper'

describe WeTransfer::Client do
  let(:small_file_name) { 'Japan-02.jpg' }
  let(:big_file) { File.open(fixtures_dir + 'Japan-01.jpg', 'rb') }
  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  it 'creates a board with files and web items as a block' do
    # Create a board with three items, one small file, one multipart file, and one web url
    board = client.create_board(name: 'Test Board', description: 'Test description') do |b|
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      b.add_file(name: 'big file', io: big_file)
      b.add_file_at(path: fixtures_dir + small_file_name)
      b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
    end

    # the board url is set
    expect(board.url =~ %r|https://we.tl/b-|).to be_truthy

    expect(board.items.map(&:class)).to eq([RemoteFile, RemoteFile, RemoteFile, RemoteLink])
    expect(board.items[1].multipart.part_numbers).to be > 1
    expect(board.items.count).to be(4)

    # Add two new items to the board, one small file and one web url
    client.add_items(board: board) do |b|
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      b.add_web_url(url: 'http://www.google.com', title: 'google')
    end
    expect(board.items.count).to be(6)

    # Check if the board includes 3 File items and 2 Link items
    expect(board.items.select { |i| i.type == 'file' }.count).to be(4)
    expect(board.items.select { |i| i.type == 'link' }.count).to be(2)

    # Upload the Files to the Board
    file_items = board.items.select { |i| i.type == 'file' }
    client.upload_file(object: board, file: file_items[0], io: File.open(__FILE__, 'rb'))
    client.upload_file(object: board, file: file_items[1], io: big_file)
    client.upload_file(object: board, file: file_items[2], io: File.open(fixtures_dir + small_file_name, 'rb'))
    client.upload_file(object: board, file: file_items[3], io: File.open(__FILE__, 'rb'))

    # Complete all the files of the board
    file_items.each do |item|
      client.complete_file!(object: board, file: item)
    end

    # Do a get request to see if url is available
    response = Faraday.get(board.url)

    # that should redirect us...
    expect(response.status).to eq(302)
    # ... to a board in the wetransfer domain
    expect(response['location']).to start_with('https://boards.wetransfer')

    # Check for the Boards status to be downloadable
    resulting_board = loop do
      res = client.get_board(board: board)
      break res if res.state != 'processing'
      sleep 1
    end

    expect(resulting_board.state).to eq('downloadable')
    expect(resulting_board.items.count).to be(6)
  end
end
