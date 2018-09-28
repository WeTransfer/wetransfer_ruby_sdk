require 'spec_helper'

describe TransferBuilder do
  let(:transfer) { described_class.new }

  describe '#initialze' do
    it 'initializes with an empty items array' do
      expect(transfer.items.empty?).to be(true)
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
      }.to raise_error ArgumentError, /io/
    end

    it 'returns a error when file doesnt exists' do
      expect {
        transfer.add_file(name: 'file name', io: File.open('foo', 'rb'))
      }.to raise_error Errno::ENOENT
    end

    it 'adds a file when name and io is given' do
      transfer.add_file(name: 'file name', io: File.open(__FILE__, 'rb'))
      expect(transfer.items.first).to be_kind_of(FutureFile)
    end
  end

  describe '#add_file_at' do
    it 'adds a file from a path' do
      transfer.add_file_at(path: __FILE__)
      expect(transfer.items.first).to be_kind_of(FutureFile)
    end

    it 'throws a Error when file doesnt exists' do
      expect {
        transfer.add_file_at(path: '/this/path/leads/to/nothing.exe')
      }.to raise_error Errno::ENOENT
    end

    it 'should call #add_file' do
      pending
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      client.create_transfer(message: 'A transfer message') do |t|
        t.add_file_at(path: __FILE__)
        t.add_file(name: 'file name', io: File.open(__FILE__, 'rb'))
        expect(t).to receive(:add_file).with(name: anything, io: kind_of(::IO))
        t.add_file_at(path: __FILE__)
      end
    end
  end
end
