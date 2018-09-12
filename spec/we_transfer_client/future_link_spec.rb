require 'spec_helper'

describe FutureLink do
  let (:params) { { url: 'http://www.wetransfer.com', title: 'WeTransfer' } }

  describe '#initializer' do
    it 'needs a :url keyword arg' do
      params.delete(:url)
      expect {
        described_class.new(params)
      }.to raise_error(ArgumentError, /url/)
    end

    it 'takes url when no title is given' do
      params.delete(:title)
      expect(described_class.new(params).title).to be(params.fetch(:url))
    end

    it 'succeeds if given all arguments' do
      described_class.new(params)
    end
  end

  describe '#to_request_params' do
    it 'creates params properly' do
      as_params = described_class.new(params).to_request_params

      expect(as_params[:url]).to eq('http://www.wetransfer.com')
      expect(as_params[:title]).to be_kind_of(String)
    end
  end

  describe 'getters' do
    let(:subject) { described_class.new(params) }

    it '#url' do
      subject.url
    end

    it '#title' do
      subject.title
    end
  end
end
