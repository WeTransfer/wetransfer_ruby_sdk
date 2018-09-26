require 'spec_helper'

describe FutureFile do
  let(:params) { { name: 'yes', io: File.open(__FILE__, 'rb') } }

  describe '#initilizer' do
    it 'needs an :io keyword arg' do
      params.delete(:io)

      expect {
        described_class.new(params)
      }.to raise_error(ArgumentError, /io/)
    end

    it 'needs a :name keyword arg' do
      params.delete(:name)

      expect {
        described_class.new(params)
      }.to raise_error(ArgumentError, /name/)
    end

    it 'succeeds if given all arguments' do
      described_class.new(params)
    end
  end

  describe '#to_request_params' do
    it 'returns a hash with name and size' do
      as_params = described_class.new(params).to_request_params

      expect(as_params[:name]).to eq('yes')
      expect(as_params[:size].class).to eq(Fixnum)
    end
  end

  describe 'getters' do
    let(:subject) { described_class.new(params) }

    it '#name' do
      subject.name
    end

    it '#io' do
      subject.io
    end
  end
end
