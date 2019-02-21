require 'spec_helper'

describe WeTransfer::MiniIO do
  subject(:mini_io) { described_class.new(io_spy) }
  let(:io_spy) { instance_double(StringIO) }

  context "wraps the io" do
    it "delegates #read" do
      expect(io_spy)
        .to receive(:read)
        .with(:foo)

      mini_io.read(:foo)
    end

    it "delegates #seek" do
      expect(io_spy)
        .to receive(:seek)
        .with(:bar)

      mini_io.seek(:bar)
    end

    it "delegates #rewind" do
      expect(io_spy)
        .to receive(:rewind)
        .with(no_args)

      mini_io.rewind
    end

    it "delegates #size" do
      expect(io_spy)
        .to receive(:size)
        .with(no_args)

      mini_io.size
    end
  end

  describe "#name" do
    it "guesses a name using File.basename" do
      expect(File)
        .to receive(:basename)
        .with(io_spy)

      mini_io.name
    end
  end
end
