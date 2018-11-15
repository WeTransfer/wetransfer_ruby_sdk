
require 'spec_helper'

describe WeTransfer::RemoteBoard do
  subject { described_class.new(params) }
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:board) { WeTransfer::Boards.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__)) }
  let(:fake_remote_file) {
    WeTransfer::RemoteFile.new(
      id: SecureRandom.uuid,
      name: 'Board name',
      size: Random.rand(9999999),
      url: nil,
      multipart: {
        part_numbers: Random.rand(10),
        id: SecureRandom.uuid,
        chunk_size: WeTransfer::RemoteBoard::CHUNK_SIZE,
       },
      type: 'file',
      client: client,
    )
  }
  let(:params) {
    {
      id: SecureRandom.uuid,
      state: 'downloadable',
      url: 'http://wt.tl/123abcd',
      name: 'RemoteBoard',
      description: 'Test Description',
      items: [
        {
          id: 's7l1urvgqs1b6u9v720180911093825',
          name: 'board_integration_spec.rb',
          size: 3036,
          multipart: {
            part_numbers: 1,
            chunk_size: 3036
          },
          type: 'file',
          client: client,
        },
        {
          id: 'storr6ua2l1fsl8lt20180911093826',
          url: 'https://www.developers.wetransfer.com',
          meta: {title: 'WeTransfer Dev Portal'},
          type: 'link',
        }
      ],
      success: true,
    }
  }

  describe '#initializer' do
    it 'is valid with all params' do
      subject
    end

    it 'is valid without description' do
      params.delete(:description)
      subject
    end

    it 'is valid without items' do
      params.delete(:items)
      subject
    end

    %i[id name state url].each do |param|
      it "is invalid without #{param}" do
        params.delete(param)
        expect {
          subject
        }.to raise_error ArgumentError, %r[#{param}]
      end
    end

    describe 'items' do
      it 'are instantiated' do
        expect(subject.items.map(&:class)).to eq([WeTransfer::RemoteFile, WeTransfer::RemoteLink])
      end

      it 'raises ItemTypeError if the item has a wrong type' do
        params[:items] = [{ type: 'foo' }]
        expect { subject }.to raise_error(WeTransfer::RemoteBoard::ItemTypeError)
      end
    end
  end

  describe '#files' do
    it 'returns only file item' do
      expect(subject.items.size).to eq(2)
      expect(subject.files.size).to eq(1)
    end
  end

  describe '#links' do
    it 'returns only link item' do
      expect(subject.items.size).to eq(2)
      expect(subject.links.size).to eq(1)
    end
  end

  describe '#prepare_file_upload' do
    before do
      board.add_items { |f| f.add_file(name: 'foo.gif', size: 123456) }
    end

    let(:remote_file) { board.remote_board.items.first }
    let(:response) { subject.prepare_file_upload(file: remote_file, part_number: 1) }

    it 'returns a Array with url and Chunksize' do
      expect(response).to be_kind_of(Array)
      expect(response.size).to be(2)
    end

    it 'returns the upload url for the part_number first' do
      expect(response.first).to start_with('https://wetransfer-eu-prod-spaceship')
    end

    it 'reutrns the size of the part as second item in the array' do
      expect(response.last).to be_kind_of(Integer)
    end
  end

  describe '#prepare_file_completion' do
    before do
      @new_board = WeTransfer::Boards.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__))
      @new_board.add_items { |f| f.add_file(name: File.basename(__FILE__), size: File.size(__FILE__)) }
    end
    let(:remote_file) { @new_board.remote_board.items.first }

    it 'send the file to the complete action' do
      @new_board.upload_file!(io: File.open(__FILE__, 'rb'))
      resp = @new_board.remote_board.prepare_file_completion(file: remote_file)
      expect(resp[:success]).to be true
      expect(resp[:message]).to eq('File is marked as complete.')
    end

    it 'returns an error when file is not uploaded' do
      expect {
        subject.prepare_file_completion(file: remote_file)
      }.to raise_error WeTransfer::Client::Error, /expected at least 1 part/
    end

    it 'returns an error when file is not in collection' do
      expect {
        subject.prepare_file_completion(file: fake_remote_file)
      }.to raise_error WeTransfer::Client::Error, /File not found./
    end
  end

  describe '#Files' do
    before do
      @new_board = WeTransfer::Boards.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__))
      @new_board.add_items do |f|
        f.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
        f.add_web_url(url: 'http://www.developers.wetransfer.com')
      end
    end

    it 'it only lists files from remote board' do
      expect(@new_board.remote_board.files.map(&:class)).to_not include(WeTransfer::RemoteLink)
    end
  end

  describe '#links' do
    before do
      @new_board = WeTransfer::Boards.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__))
      @new_board.add_items do |f|
        f.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
        f.add_web_url(url: 'http://www.developers.wetransfer.com')
      end
    end

    it 'it only lists files from remote board' do
      expect(@new_board.remote_board.links.map(&:class)).to_not include(WeTransfer::RemoteFile)
    end
  end

  describe '#select_file_on_name' do
    #todo
  end

  describe 'getters' do
    %i[id items url state].each do |getter|
      it "responds to ##{getter}" do
        subject.send getter
      end
    end
  end
end
