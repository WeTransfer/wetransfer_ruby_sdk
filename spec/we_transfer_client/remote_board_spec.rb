
require 'spec_helper'

describe RemoteBoard do
  subject { described_class.new(params) }

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
          url: 'http://www.wetransfer.com',
          meta: {title: 'WeTransfer Website'},
          type: 'link',
        }
      ]
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
        expect(subject.items.map(&:class)).to eq([RemoteFile, RemoteLink])
      end

      it 'raises ItemTypeError if the item has a wrong type' do
        params[:items] = [{ type: 'foo' }]
        expect { subject }.to raise_error(RemoteBoard::ItemTypeError)
      end
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
