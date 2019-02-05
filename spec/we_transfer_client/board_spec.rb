require 'spec_helper'

describe WeTransfer::Board do
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger) }
  let(:small_file_location) { fixtures_dir + 'small_file.1.txt' }
  describe 'Initialize' do
    it 'has client, future and remote board as instance_variable' do
      WtVCR.laserdisc do
        expect(described_class.new(client: client, name: 'New Board', description: 'This is the description').instance_variables).to include(:@client, :@remote_board)
      end
    end

    it 'creates a board and uploads the files' do
      WtVCR.laserdisc do
        board = described_class.new(client: client, name: 'test', description: 'test description')
        board.add_items do |b|
          b.add_file(name: File.basename(small_file_location), size: File.size(small_file_location))
          b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
        end

        expect(board.remote_board).to be_kind_of(WeTransfer::RemoteBoard)
        expect(board.remote_board.url).to start_with('https://we.tl/')
        expect(board.remote_board.state).to eq('downloadable')
      end
    end
  end

  describe '#add_items' do
    let(:board) {
      described_class.new(client: client, name: 'Board', description: 'pre-made board')
    }

    # it 'adds items to a remote board' do
    #   board.add_items do |b|
    #     b.add_file(name: File.basename(small_file_location), size: File.size(small_file_location))
    #     b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
    #     b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
    #     b.add_file_at(path: fixtures_dir + 'Japan-02.jpg')
    #   end
    #   expect(board.remote_board.items.count).to eq(4)
    #   expect(board.remote_board.files.count).to eq(3)
    # end

    it 'raises an error when a filename already exists in the board' do
      WtVCR.laserdisc do
        expect {
          board.add_items do |b|
            b.add_file(name: File.basename(small_file_location), size: File.size(small_file_location))
            b.add_file(name: File.basename(small_file_location), size: File.size(small_file_location))
          end
        }.to raise_error WeTransfer::TransferIOError, 'Duplicate file entry'
      end
    end

    it 'raises an error when a links already exisits in the board' do
      WtVCR.laserdisc do
        expect {
          board.add_items do |b|
            b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
            b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
          end
        }.to raise_error WeTransfer::TransferIOError, 'Duplicate link entry'
      end
    end
  end

  describe '#upload_file!' do
    let(:board) {
      board = described_class.new(client: client, name: 'Board', description: 'pre-made board')
      board.add_items do |b|
        b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
        b.add_file(name: File.basename(small_file_location), size: File.size(small_file_location))
      end
      board
    }

    it 'after adding links and files the files are uploaded to the board' do
      WtVCR.laserdisc do
        expect {
          board.upload_file!(name: File.basename(small_file_location), io: File.open(small_file_location, 'rb'))
        }.not_to raise_error
      end
    end

    it 'raises an error when io keyword is missing' do
      WtVCR.laserdisc do
        expect {
          board.upload_file!(name: File.basename(small_file_location))
        }.to raise_error ArgumentError
      end
    end

    it 'raises an error when trying to upload non existing files' do
      WtVCR.laserdisc do
        expect {
          board.upload_file!(name: 'nowhere.gif', io: File.open('/this/is/a/path/to/nowhere.gif', 'rb'))
        }.to raise_error Errno::ENOENT
      end
    end

    it "raises an error when file size doesn't match" do
      WtVCR.laserdisc do
        expect {
          board.upload_file!(name: 'Japan-01.jpg', io: File.open(small_file_location))
        }.to raise_error WeTransfer::TransferIOError
      end
    end

    it 'uploads a file if name and path are given' do
      WtVCR.laserdisc do
        expect {
          board.upload_file!(name: File.basename(small_file_location), io: File.open(small_file_location, 'rb'))
        }.not_to raise_error
      end
    end

    it 'returns a RemoteFile after uploading' do
      WtVCR.laserdisc do
        response = board.upload_file!(name: File.basename(small_file_location), io: File.open(small_file_location, 'rb'))

        expect(response).to be_kind_of(WeTransfer::RemoteFile)
      end
    end
  end

  describe '#complete_file' do
    let(:board) {
      board = described_class.new(client: client, name: 'Board', description: 'pre-made board')
      board.add_items do |b|
        b.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
        b.add_file(name: File.basename(small_file_location), size: File.size(small_file_location))
        b.add_file_at(path: fixtures_dir + 'Japan-01.jpg')
      end

      board.upload_file!(name: File.basename(small_file_location), io: File.open(small_file_location, 'rb'))
      board.upload_file!(io: File.open(fixtures_dir + 'Japan-01.jpg', 'rb'))
      board
    }

    it 'completes files without raising an error' do
      WtVCR.laserdisc do
        expect {
          board.complete_file!(name: 'Japan-01.jpg')
          board.complete_file!(name: File.basename(small_file_location))
        }.not_to raise_error
      end
    end

    it "raises an error when file doesn't exists" do
      WtVCR.laserdisc do
        expect {
          board.complete_file!(name: 'i-do-not-exist.gif')
        }.to raise_error WeTransfer::TransferIOError
      end
    end

    it "raises an error when file doesn't match" do
      WtVCR.laserdisc do
        expect {
          board.complete_file!(name: 'Japan-02.jpg')
        }.to raise_error WeTransfer::TransferIOError
      end
    end
  end
end
