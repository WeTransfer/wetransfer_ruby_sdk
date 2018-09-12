require 'spec_helper'

describe RemoteBoard do
  let (:params) {
    {
      id: [*('a'..'z'), *('0'..'9')].shuffle[0, 36].join,
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
          type: 'file'
        },
        {
          id: 'storr6ua2l1fsl8lt20180911093826',
          url: 'http://www.wetransfer.com',
          meta:
            {
              title: 'WeTransfer Website'
            },
          type: 'link'
        }
      ]
    }}

  describe '#initializer' do
    it 'initialized when no description is given' do
      params.delete(:description)
      described_class.new(params)
    end

    it 'initialized when no item is given' do
      params.delete(:items)
      described_class.new(params)
    end

    it 'fails when id is missing' do
      params.delete(:id)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /id/
    end

    it 'fails when state is missing' do
      params.delete(:state)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /state/
    end

    it 'fails when url is missing' do
      params.delete(:url)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /url/
    end

    it 'fails when name is missing' do
      params.delete(:name)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /name/
    end

    it 'creates new object' do
      described_class.new(params)
    end

    it 'creates classes for items' do
      remote_board = described_class.new(params)
      expect(remote_board.items.map(&:class)).to eq([RemoteFile, RemoteLink])
    end
  end

  describe 'getter' do
    let (:subject) { described_class.new(params) }

    it '#id' do
      subject.id
    end

    it '#items' do
      subject.items
    end

    it '#url' do
      subject.url
    end

    it '#state' do
      subject.state
    end
  end
end
