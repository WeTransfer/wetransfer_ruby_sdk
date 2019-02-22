require 'spec_helper'

describe WeTransfer::Client do
  subject { described_class.new(params) }
  let(:params) { { api_key: ENV.fetch('WT_API_KEY') } }

  it 'exposes VERSION' do
    expect(WeTransfer::VERSION).to be_kind_of(String)
  end

  describe "#create_transfer" do
    let(:transfer) { instance_double(WeTransfer::Transfer) }

    it "raises an ArgumentError without the :message keyword param" do
      expect { subject.create_transfer }.to raise_error(ArgumentError, %r/message/)
    end

    it "instantiates a Transfer" do
      allow(transfer)
        .to receive(:persist)

      expect(WeTransfer::Transfer)
        .to receive(:new)
        .with(message: 'fake transfer')
        .and_return(transfer)

      subject.create_transfer(message: 'fake transfer')
    end

    it "stores the transfer in @transfer" do
      allow(transfer)
        .to receive(:persist)

      allow(WeTransfer::Transfer)
        .to receive(:new)
        .and_return(transfer)
      subject.create_transfer(message: 'test transfer')

      expect(subject.instance_variable_get(:@transfer)).to eq transfer
    end

    it "accepts a block, that is passed to the Transfer instance" do
      allow(WeTransfer::Transfer)
        .to receive(:new)
        .with(message: 'test transfer')
        .and_return(transfer)

      expect(transfer)
        .to receive(:persist) { |&transfer| transfer.call(name: 'test file', size: 8) }

      expect { |probe| subject.create_transfer(message: 'test transfer', &probe) }
        .to yield_with_args(name: 'test file', size: 8)
    end

    it "returns self" do
      allow(transfer)
        .to receive(:persist)

      allow(WeTransfer::Transfer)
        .to receive(:new)
        .and_return(transfer)

      expect(subject.create_transfer(message: 'test transfer')).to eq subject
    end
  end

  describe "#find_transfer" do
    it "delegates to Transfer.find" do
      transfer_id = 'fake-transfer-id'
      expect(WeTransfer::Transfer)
        .to receive(:find)
        .with(transfer_id)

      subject.find_transfer(transfer_id)
    end

    it "stores the found transfer in @transfer"
  end
end
