require 'spec_helper'

describe RemoteFile do
  let(:params) {
    {
      id: [*('a'..'z'), *('0'..'9')].shuffle[0, 36].join,
      name: 'Board name',
      size: Random.rand(9999999),
      url: nil,
      multipart: {
        part_numbers: Random.rand(10),
        id: [*('a'..'z'), *('0'..'9')].shuffle[0, 36].join,
        chunk_size:  6 * 1024 * 1024,
      },
      type: 'file',
    }}

  describe '#initializer' do
    it 'initialized when no url is given' do
      params.delete(:url)
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
      params.delete(:size)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /size/
    end

    it 'fails when url is missing' do
      params.delete(:multipart)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /multipart/
    end

    it 'fails when name is missing' do
      params.delete(:name)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /name/
    end

    it 'must have a struct in multipart' do
      remote_file = described_class.new(params)
      expect(remote_file.multipart).to be_kind_of(Struct)
    end

    it 'multipart has partnumber, id and chunk_size keys' do
      remote_file = described_class.new(params)
      expect(remote_file.multipart.members).to eq(params[:multipart].keys)
    end
  end

  describe 'Getters' do
    let(:subject) { described_class.new(params) }

    it '#multipart' do
      subject.multipart
    end

    it '#name' do
      subject.name
    end

    it '#type' do
      subject.type
    end

    it '#id' do
      subject.id
    end

    it '#url' do
      subject.url
    end
  end
end
