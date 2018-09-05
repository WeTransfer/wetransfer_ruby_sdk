require 'spec_helper'

describe RemoteBoard do
  let (:params) { { id: Random.rand(9999),
                    state: 'downloadable',
                    url: 'http://wt.tl/123abcd',
                    name:'RemoteBoard',
                    description: 'Test Description',
                    items: []
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
  end
end