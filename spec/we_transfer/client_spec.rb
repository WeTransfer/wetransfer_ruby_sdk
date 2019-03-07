require 'spec_helper'

describe WeTransfer::Client do
  subject(:client) { described_class.new(api_key: fake_key) }
  let(:fake_key) { "fake key" }
  let(:communicator) { instance_double(WeTransfer::Communicator) }

  it 'exposes VERSION' do
    expect(WeTransfer::VERSION).to be_kind_of(String)
  end

  before do
    allow(WeTransfer::Communicator)
      .to receive(:new)
      .and_return(communicator)
  end

  describe "initializer" do
    it "needs an :api_key kw param" do
      expect { described_class.new }
        .to raise_error(ArgumentError, %r|api_key|)

      expect { described_class.new(api_key: 'fake key') }
        .to_not raise_error
    end

    it "initializes a WeTransfer::Communicator" do
      expect(WeTransfer::Communicator)
        .to receive(:new)
        .with(fake_key)

      subject
    end

    it "stores the Communicator instance in @communicator" do
      allow(WeTransfer::Communicator)
        .to receive(:new)
        .and_return(communicator)

      expect(subject.instance_variable_get(:@communicator))
        .to eq communicator
    end
  end

  describe "#create_transfer" do
    let(:transfer) { instance_double(WeTransfer::Transfer) }

    it "instantiates a Transfer with all needed arguments" do
      allow(transfer)
        .to receive(:persist)

      expect(WeTransfer::Transfer)
        .to receive(:new)
        .with(
          message: 'fake transfer',
          communicator: communicator
        )
        .and_return(transfer)

      subject.create_transfer(message: 'fake transfer')
    end

    it "accepts a block, that is passed to the persist method of the Transfer instance" do
      allow(WeTransfer::Transfer)
        .to receive(:new)
        .and_return(transfer)

      expect(transfer)
        .to receive(:persist) { |&transfer| transfer.call(name: 'test file', size: 8) }

      expect { |probe| subject.create_transfer(message: 'test transfer', &probe) }
        .to yield_with_args(name: 'test file', size: 8)
    end
  end

  describe "#find_transfer" do
    it "is delegated to communicator" do
      transfer_id = 'fake-transfer-id'

      expect(communicator)
        .to receive(:find_transfer)
        .with(transfer_id)

      subject.find_transfer(transfer_id)
    end
  end
end
