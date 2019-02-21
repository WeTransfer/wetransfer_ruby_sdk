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

    it "delegates the size to io if unavailable" do
      io = File.open('Gemfile')

      expect(File)
        .to receive(:basename)
        .with(io)
        .and_return "delegated"

      described_class.new(io: io)
    end
    it "wraps the IO in a MiniIO"
  end
end
