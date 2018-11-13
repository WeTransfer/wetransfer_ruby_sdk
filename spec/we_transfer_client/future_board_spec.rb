require 'spec_helper'

describe WeTransfer::FutureBoard do
  let(:params) { { name: 'yes', description: 'A description about the board' } }

  describe '#initializer' do
    it 'raises ArgumentError when no name is given' do
      params.delete(:name)
      expect {
        described_class.new(params)
      }.to raise_exception ArgumentError, /name/
    end

    it 'accepts a blank description' do
      params.delete(:description)
      described_class.new(params)
    end
  end

  describe '#to_initial_request_params' do
    it 'has a name' do
      as_request_params = described_class.new(params).to_initial_request_params
      expect(as_request_params[:name]).to be(params[:name])
    end

    it 'has a description' do
      as_request_params = described_class.new(params).to_initial_request_params
      expect(as_request_params[:description]).to be(params[:description])
    end

    it 'when no description is given, the value of the key is empty' do
      params.delete(:description)
      as_request_params = described_class.new(params).to_initial_request_params
      expect(as_request_params[:description]).to be_nil
    end
  end

  describe 'getters' do
    let (:subject) { described_class.new(params)}

    %i(name description).each do |getter|
      it "responds to ##{getter}" do
        subject.send getter
      end
    end
  end
end
