require 'spec_helper'

describe WeTransfer::WeTransferFile do
  describe "initializer" do
    it "works with an IO that provides a name"
    it "works with an IO and a name"
    it "works with a name and a size"

    it "raises if name is unavailable" do
      nameless_io = StringIO.new('I have no name, but a size I have')
      expect { described_class.new(io: nameless_io) }
        .to raise_error(ArgumentError)

      expect { described_class.new(size: 10) }
        .to raise_error(ArgumentError)
    end

    it "raises if size is unavailable" do
      expect { described_class.new(name: 'README') }
        .to raise_error(ArgumentError)
    end

    it "infers the name using File.basename, with the io as its arg" do
      io = File.open('Gemfile')

      expect(File)
        .to receive(:basename)
        .with(io)
        .and_return "delegated"

      described_class.new(io: io)
    end

    it "wraps the io in MiniIO" do
      io = :foo
      expect(WeTransfer::MiniIO)
        .to receive(:new)
        .with(io)

      described_class.new(io: io, name: 'test file', size: 8)
    end
  end

  describe "getters" do
    subject { described_class.new(io: File.open('Gemfile')) }

    %i[name id io multipart].each do |getter|
      it "has a getter for :#{getter}" do
        expect { subject.send getter }.to_not raise_error
      end
    end
  end

  describe "#as_persist_params" do
    subject(:file) { described_class.new(name: 'test file', size: 8) }

    it "has key/values for name and size only" do
      expect(file.as_persist_params.to_json)
        .to eq %|{"name":"test file","size":8}|
    end
  end

  describe "#to_h" do
    let(:file) { described_class.new(name: 'foo', size: 8) }
    let(:multipart_stub) { instance_double(WeTransfer::RemoteFile::Multipart) }

    it "has keys and values for id, name, size and multipart" do
      allow(file)
        .to receive(:multipart)
        .and_return(multipart_stub)

      allow(file)
        .to receive(:id)
        .and_return('fake-id')

      allow(multipart_stub)
        .to receive(:to_h)
        .and_return('fake-multipart')

      expected = {
        id: 'fake-id',
        multipart: 'fake-multipart',
        size: 8,
        name: 'foo'

      }

      expect(file.to_h)
        .to match(expected)
    end

    it "calls :to_h on multipart" do
      allow(file)
        .to receive(:multipart)
        .and_return(multipart_stub)

      expect(multipart_stub)
        .to receive(:to_h)

      file.to_h
    end
  end
end
