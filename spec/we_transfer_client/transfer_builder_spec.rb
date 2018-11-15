require 'spec_helper'

describe WeTransfer::TransferBuilder do
  let(:transfer) { described_class.new }

  describe '#initialze' do
    it 'initializes with an empty files array' do
      expect(transfer.files.empty?).to be(true)
    end
  end

  describe '#add_file' do
    it 'returns an error when name is missing' do
      expect {
        transfer.add_file(io: File.open(__FILE__, 'rb'))
      }.to raise_error ArgumentError, /name/
    end

    it 'returns an error when io is missing' do
      expect {
        transfer.add_file(name: 'file name')
      }.to raise_error ArgumentError, /size/
    end

    it 'returns a error when file doesnt exists' do
      expect {
        transfer.add_file(name: 'file name', size: File.size('foo.gif',))
      }.to raise_error Errno::ENOENT
    end

    it 'adds a file when name and io is given' do
      transfer.add_file(name: 'file name', size: File.size(__FILE__))
      expect(transfer.files.first).to be_kind_of(WeTransfer::FutureFile)
    end
  end

  describe '#add_file_at' do
    it 'adds a file from a path' do
      transfer.add_file_at(path: __FILE__)
      expect(transfer.files.first).to be_kind_of(WeTransfer::FutureFile)
    end

    it 'throws a Error when file doesnt exists' do
      expect {
        transfer.add_file_at(path: '/this/path/leads/to/nothing.exe')
      }.to raise_error Errno::ENOENT
    end
  end
end
