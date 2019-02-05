require 'spec_helper'

describe FutureTransfer do
  let(:transfer) { described_class }

  describe '#initialize' do
    it 'creates an empty array when initialized' do
      expect(transfer.new(message: 'transfer').files).to be_kind_of(Array)
    end

    it 'raises an error when message is not given' do
      expect {
        transfer.new
      }.to raise_error ArgumentError
    end
  end

  describe 'getters' do
    it 'message' do
      transfer.new(message: 'test').message
    end

    it 'files' do
      transfer.new(message: 'test').files
    end
  end

  describe 'to_request_params' do
    it 'includes the message' do
      new_transfer = transfer.new(message: 'test')
      expect(new_transfer.to_request_params[:message]).to be(new_transfer.message)
    end

    it 'includes the files as an array' do
      new_transfer = transfer.new(message: 'test')
      expect(new_transfer.to_request_params[:files]).to eq([])
    end
  end
end
