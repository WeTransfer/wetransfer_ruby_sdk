require 'spec_helper'

describe WeTransfer::TransferBuilder do
  let(:client)   { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:transfer) { WeTransfer::Transfer.new(client: client, message: 'TestMessage') }
  subject(:transfer_builder) { described_class.new(transfer: transfer) }

  describe '#initialize' do
    it 'initializes with an empty files array' do
      expect(transfer_builder.files.empty?).to be(true)
    end
  end

  describe '#add_file' do
    it 'raises an error when name is missing' do
      expect {
        transfer_builder.add_file(size: File.open(__FILE__, 'rb'))
      }.to raise_error ArgumentError, /name/
    end

    it 'raises an error when size is missing' do
      expect {
        transfer_builder.add_file(name: 'file name')
      }.to raise_error ArgumentError, /size/
    end

    it "raises an error when file doesn't exists" do
      expect {
        transfer_builder.add_file(name: 'file name', size: File.size('no-such-file.here'))
      }.to raise_error Errno::ENOENT
    end

    it 'adds a file when name and size is given' do
      transfer_builder.add_file(name: 'file name', size: File.size(__FILE__))
      expect(transfer_builder.files.first).to be_kind_of(WeTransfer::FutureFile)
    end
  end

  describe '#add_file_at' do
    it 'adds a file from a path' do
      transfer_builder.add_file_at(path: __FILE__)
      expect(transfer_builder.files.first).to be_kind_of(WeTransfer::FutureFile)
    end

    it "throws an Errno::ENOENT when the file doesn't exist" do
      expect {
        transfer_builder.add_file_at(path: 'no-such-file.here')
      }.to raise_error Errno::ENOENT
    end
  end
end
