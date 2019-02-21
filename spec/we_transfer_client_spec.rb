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
      expect(WeTransfer::Transfer)
        .to receive(:new)
        .with(message: 'fake transfer')
        .and_return(transfer)

      subject.create_transfer(message: 'fake transfer')
    end

    it "stores the transfer in @transfer" do
      allow(WeTransfer::Transfer)
        .to receive(:new)
        .and_return(transfer)
      subject.create_transfer(message: 'foo')

      expect(subject.instance_variable_get(:@transfer)).to eq transfer
    end

    it "accepts a block, that is passed to the Transfer instance" do
      allow(WeTransfer::Transfer)
        .to receive(:new) { |&transfer| transfer.call(name: 'meh') }
        .with(message: "foo")
        .and_return(transfer)

      expect { |probe| subject.create_transfer(message: 'foo', &probe) }.to yield_with_args(name: 'meh')
    end

    it "returns self" do
      allow(WeTransfer::Transfer)
        .to receive(:new)
        .and_return(transfer)
      expect(subject.create_transfer(message: 'foo')).to eq subject
    end
  end

  describe "integrations" do
    it "works" do
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'))
      transfer = client.create_transfer(message: 'test transfer') do |transfer|
        transfer.add_file(name: 'test_file', size: 30)
      end
      # binding.pry
    end
  end
end
