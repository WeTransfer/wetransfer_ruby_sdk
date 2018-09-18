require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransfer::Client do
  TWO_CHUNKS_FILE_NAME = 'spec/testdir/two_chunks'

  before(:all) do
    Dir.mkdir('spec/testdir') unless Dir.exist?('spec/testdir')
    unless File.exist?(TWO_CHUNKS_FILE_NAME)
      File.open(TWO_CHUNKS_FILE_NAME, 'w') do |f|
        f.puts('-' * (described_class::MAGIC_PART_SIZE + 3))
        puts File.absolute_path(f)
      end
    end
  end

  let(:two_chunks) { File.open("#{Dir.pwd}/#{TWO_CHUNKS_FILE_NAME}", 'r') }

  let(:test_logger) do
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end

  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  pending "this talks to production, and it doesn't know about the meta-change of web_content" do
    # it 'should create a board with files and web items as a block' do

    # create a new board with a small file, bigger multipart file and a link
    board = client.create_board(name: 'Test Board', description: 'Test description') do |b|
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
      b.add_file(name: 'two_chunks', io: two_chunks)
      b.add_web_url(url: 'http://www.wetransfer.com', title: 'WeTransfer Website')
    end
    expect(board.items.map(&:class)).to eq([RemoteFile, RemoteFile, RemoteLink])
    expect(board.items[1].multipart.part_numbers).to be > 1
    expect(board.items.count).to be(3)

    # add more files to the board

    client.add_items(board: board) do |b|
      b.add_web_url(url: 'http://www.google.com', title: 'google')
      b.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
    end
    expect(board.items.count).to be(5)
    expect(board.items.select { |i| i.type == 'file' }.count).to be(3)
    expect(board.items.select { |i| i.type == 'link' }.count).to be(2)

    # actual uploading of the files to the board

    # You have to upload every file one at the time, can't itterate over it
    file_items = board.items.select { |i| i.type == 'file' }
    # File items count is 3 so you have to execute this 3 times.
    client.upload_file(object: board, file: file_items[0], io: File.open(__FILE__, 'rb'))
    client.upload_file(object: board, file: file_items[1], io: two_chunks)
    client.upload_file(object: board, file: file_items[2], io:  File.open(__FILE__, 'rb'))

    client.complete_file!(object: board, file: file_items[0])
    client.complete_file!(object: board, file: file_items[1])
    client.complete_file!(object: board, file: file_items[2])

    expect(board.url).to be_kind_of(String)
    response = Faraday.get(board.url)
    # it hits the short-url with redirect
    expect(response.status).to eq(302)
    # but check in the header for a wetransfer domain location
    expect(response['location']).to start_with('https://boards.wetransfer')

    res = client.get_board(board_id: board.id)
    if res.state == 'processing'
      # it needs to be downloadable, otherwise something failed / or spaceship is slow
      sleep(30)
      res = client.get_board(board_id: board.id)
      expect(res.state).to eq('downloadable')
    end
    expect(res.state).to eq('downloadable')

    expect(res.items.count).to be(5)
    expect(res.items.first).to be_kind_of(RemoteFile)
  end
end
