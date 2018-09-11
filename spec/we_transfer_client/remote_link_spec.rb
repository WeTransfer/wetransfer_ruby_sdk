require 'spec_helper'

describe RemoteLink do
  let (:params) {
    {
      id: [*('a'..'z'), *('0'..'9')].shuffle[0, 36].join,
      url: 'http://www.wetransfer.com',
      meta: {title: 'wetransfer.com'},
      type: 'web_content'}
    }

  describe '#initialize' do
    it 'raises an ArgumentError when id is missing' do
      params.delete(:id)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /id/
    end

    it 'raises an ArgumentError when url is missing' do
      params.delete(:url)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /url/
    end

    it 'raises an ArgumentError when id is missing' do
      params.delete(:meta)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /meta/
    end

    it 'raises an ArgumentError when id is missing' do
      params.delete(:type)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /type/
    end
  end
  describe 'getters' do
    let (:object) {described_class.new(params)}

    it '#type' do
      object.type
    end
  end
end
