require 'spec_helper'

describe WeTransfer::MiniIO do
  let(:io_spy) do
    spy = instance_double(File)
    %i[read rewind seek size].each do |acceptable_method|
      allow(spy)
        .to receive(acceptable_method)
    end

    spy
  end

  subject(:mini_io) { described_class.new(io_spy) }

  context "initializer" do
    let(:not_an_io) { "Not an IO" }
    let(:already_wrapped) { described_class.new(File.open('Gemfile')) }

    it "does not wrap the IO twice" do
      expect(described_class.new(already_wrapped))
        .to eq already_wrapped
    end

    %i[read rewind seek size].each do |required_method|
      it "raises if IO doesn't respond to #{required_method}" do
        expect { described_class.new(not_an_io) }
          .to raise_error ArgumentError, %r|#{required_method}|
      end
    end

    it "returns a NullMiniIO if called with nil" do
      expect described_class.new(nil).is_a?(WeTransfer::NullMiniIO)
    end
  end

  context "exposes specific methods on io" do
    it "#read" do
      expect(io_spy)
        .to receive(:read)
        .with(:foo)

      mini_io.read(:foo)
    end

    it "#rewind" do
      expect(io_spy)
        .to receive(:rewind)
        .with(no_args)

      mini_io.rewind
    end

    it "#seek" do
      expect(io_spy)
        .to receive(:seek)
        .with(:bar)

      mini_io.seek(:bar)
    end

    it "#size" do
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
