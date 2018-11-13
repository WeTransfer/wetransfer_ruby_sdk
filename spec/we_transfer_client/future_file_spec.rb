require 'spec_helper'

describe WeTransfer::FutureFile do
  let(:params) { { name: File.basename(__FILE__), size: File.size(__FILE__) } }
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:board) { WeTransfer::Boards.new(client: client, name: 'future_file_spec.rb', description: 'this test the behaviour of the future_file') }
  let(:fake_remote_board) {
    WeTransfer::RemoteBoard.new(
      id: SecureRandom.uuid,
      state: 'downloadable',
      url: 'http://wt.tl/123abcd',
      name: 'RemoteBoard',
      description: 'Test Description',
      success: true, # TODO: Need to ommit this
    )
  }
  let(:file) { described_class.new(params) }
  let(:big_file) { described_class.new(name: 'Japan-01.jpg', size: File.size(fixtures_dir + 'Japan-01.jpg')) }

  describe '#initilizer' do
    it 'raises a error when size is missing in argument' do
      params.delete(:size)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /size/
    end

    it 'raises a error when name is missing in argument' do
      params.delete(:name)

      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /name/
    end

    it 'succeeds if given all arguments' do
      described_class.new(params)
    end

    it 'transfors integer names to strings' do
      new_file = described_class.new(name: 1235, size: 98653)
      expect(new_file.name).to be_kind_of(String)
    end

    it 'stringed filesizes are converted to integers' do
      new_file = described_class.new(name: 'foo.jpg', size: '1337')
      expect(new_file.size).to be_kind_of(Integer)
    end
  end

  describe '#to_request_params' do
    it 'returns a hash with name and size' do
      as_params = described_class.new(params).to_request_params

      expect(as_params[:name]).to eq('future_file_spec.rb')
      expect(as_params[:size]).to be_kind_of(Integer)
    end
  end

  describe '#add_to_board' do
    it 'add future file to a remote_board and return a RemoteFile' do
      response = file.add_to_board(client: client, remote_board: board.remote_board)
      expect(response).to be_kind_of(WeTransfer::RemoteFile)
    end

    it 'raises an error when board doenst exists' do
      expect {
        file.add_to_board(client: client, remote_board: fake_remote_board)
      }.to raise_error WeTransfer::Client::Error, /This board does not exist/
    end

    it 'adds the item to the remote board' do
      response_file = file.add_to_board(client: client, remote_board: board.remote_board)
      expect(board.remote_board.items).to include(response_file)
    end
  end

  describe '#upload_file' do
    describe 'board behaviour' do
      before do
        file.add_to_board(client: client, remote_board: board.remote_board)
      end

      it 'uploads the file and returns ok status' do
        remote_file = board.remote_board.select_file_on_name(name: File.basename(__FILE__))
        response = file.upload_file(client: client, remote_object: board.remote_board, remote_file: remote_file, io: File.open(__FILE__, 'rb'))
        expect(response).to be_kind_of(WeTransfer::RemoteFile)
      end

      it 'raises an error when file is not opened for readings' do
        local_file_io = File.new("foo.txt", "w") { |f| f.write('bar, baz, qux, quux, garply, waldo, fred, plugh, xyzzy, thud') }
        expect {
          remote_file = board.remote_board.select_file_on_name(name: File.basename(__FILE__))
          file.upload_file(client: client, remote_object: board.remote_board, remote_file: remote_file, io: local_file_io)
        }.to raise_error WeTransfer::TransferIOError
        File.delete(local_file_io.to_path)
      end

      it 'raises an error when file is not io compliant' do
        local_file_io = File.new("foo.bar", "w+")
        expect {
          remote_file = board.remote_board.select_file_on_name(name: File.basename(__FILE__))
          file.upload_file(client: client, remote_object: board.remote_board, remote_file: remote_file, io: local_file_io)
        }.to raise_error WeTransfer::TransferIOError, /foo.bar, given to add_file has a size of 0/
        File.delete(local_file_io.to_path)
      end
    end

    describe 'Transfer behaviour' do
      # Todo!
    end
  end

  describe '#complete_file' do
    describe 'boards behaviour' do
      before do
        file.add_to_board(client: client, remote_board: board.remote_board)
        @remote_file = board.remote_board.select_file_on_name(name: File.basename(__FILE__))
        file.upload_file(client: client, remote_object: board.remote_board, remote_file: @remote_file, io: File.open(__FILE__, 'rb'))
      end

      it 'completes a file when a file is eliagble to' do
        response = file.complete_file(client: client, remote_object: board.remote_board, remote_file: @remote_file)
        expect(response[:success]).to be true
      end

      it 'raises a error when file is not uploaded' do
        expect {
          big_file.add_to_board(client: client, remote_board: board.remote_board)
          remote_file = board.remote_board.select_file_on_name(name: 'Japan-01.jpg')
          file.complete_file(client: client, remote_object: board.remote_board, remote_file: remote_file)
        }.to raise_error WeTransfer::Client::Error, /expected at least 1 part/
      end
    end
    describe 'Transfer behaviour' do
      # Todo!
    end
  end

  describe '#check_for_duplicates' do
    it 'raises an error when file is already inside collection' do
      expect {
        file_list = board.remote_board.items
        file.check_for_duplicates(file_list)
      }.to raise_error WeTransfer::TransferIOError, /Duplicate file entry/
    end
  end

  describe 'getters' do
    let(:subject) { described_class.new(params) }

    %i[name size].each do |getter|
      it "responds to #{getter}" do
        subject.send getter
      end
    end
  end
end
