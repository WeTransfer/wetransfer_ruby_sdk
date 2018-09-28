require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransfer::Client do
  before(:all) do
    Dir.mkdir('spec/testdir') unless Dir.exist?('spec/testdir')
    unless File.exist?(TWO_CHUNKS_FILE_NAME)
      File.open(TWO_CHUNKS_FILE_NAME, 'w') do |f|
        f.puts('-' * (PART_SIZE + 3))
        puts File.absolute_path(f)
      end
    end
  end

  let(:two_chunks) { File.open("#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}", 'r') }

  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
  end

  it 'creates a board with files and web items as a block' do
    # Create a board with three items, one small file, one multipart file, and one web url
    board = client.create_board(name: 'Test Board', description: 'Test description') do |b|
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      b.add_file(name: 'two_chunks', io: two_chunks)
      b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
    end

    expect(board.items.map(&:class)).to eq([RemoteFile, RemoteFile, RemoteLink])
    expect(board.items[1].multipart.part_numbers).to be > 1
    expect(board.items.count).to be(3)

    # Add two new items to the board, one small file and one web url
    client.add_items(board: board) do |b|
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      b.add_web_url(url: 'http://www.google.com', title: 'google')
    end
    expect(board.items.count).to be(5)

    # Check if the board includes 3 File items and 2 Link items
    expect(board.items.select { |i| i.type == 'file' }.count).to be(3)
    expect(board.items.select { |i| i.type == 'link' }.count).to be(2)

    # Upload the Files to the Board
    file_items = board.items.select { |i| i.type == 'file' }
    client.upload_file(object: board, file: file_items[0], io: File.open(__FILE__, 'rb'))
    client.upload_file(object: board, file: file_items[1], io: two_chunks)
    client.upload_file(object: board, file: file_items[2], io: File.open(__FILE__, 'rb'))

    # Complete the Files of the board
    client.complete_file!(object: board, file: file_items[0])
    client.complete_file!(object: board, file: file_items[1])
    client.complete_file!(object: board, file: file_items[2])

    # The Board url should be accesible
    expect(board.url).to be_kind_of(String)

    # Do a get request to see if url is available
    response = Faraday.get(board.url)

    # it hits the short-url with redirect
    expect(response.status).to eq(302)

    # but check in the header for a wetransfer domain location
    expect(response['location']).to start_with('https://boards.wetransfer')

    # Check for the Boards status to be downloadable
    resulting_board = loop do
      res = client.get_board(board: board)
      break res if res.state != 'processing'
      sleep 1
    end

    expect(resulting_board.state).to eq('downloadable')
    expect(resulting_board.items.count).to be(5)
  end
end
