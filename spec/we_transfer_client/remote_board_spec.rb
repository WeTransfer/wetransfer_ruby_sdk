
require 'spec_helper'

describe WeTransfer::RemoteBoard do
  subject { described_class.new(params) }
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:board) { WeTransfer::Boards.new(client: client, name: File.basename(__FILE__), description: File.basename(__FILE__)) }
  let(:remote_file) { WeTransfer::RemoteFile.new(id: SecureRandom.uuid, name: 'Board name', size: Random.rand(9999999), url: nil, multipart: { part_numbers: Random.rand(10), id: SecureRandom.uuid, chunk_size: WeTransfer::RemoteBoard::CHUNK_SIZE, }, type: 'file',) }
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

  describe '#initializer', :focus do
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

  describe '#prepare_file_upload', :focus do
    it 'returns a Array with url and Chunksize' do
      resp = subject.prepare_file_upload(client: client, file: remote_file, part_number: 1)
      binding.pry
    end
  end

  describe 'getters' do
    %i[id items url state].each do |getter|
      it "responds to ##{getter}" do
        subject.send getter
      end
    end
  end
end
