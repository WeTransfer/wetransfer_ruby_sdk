require 'spec_helper'

describe WeTransfer::Client::Transfers do
  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  let(:file_location) { fixtures_dir + 'Japan-02.jpg' }

  let(:created_transfer) do
    client.create_transfer(message: 'Test transfer') do |builder|
      builder.add_file(name: File.basename(file_location), io: File.open(file_location, 'rb'))
    end
  end

  describe "#create_transfer" do
    before do
      skip "this interface is still experimental"
    end

    it "is needed to add a file" do
      expect { client.create_transfer(message: "Transfer name") }
        .to raise_error(ArgumentError, /^No files were added/)
    end

    it "accepts a block to add files by their location" do
      client.create_transfer(message: 'Test transfer') do |builder|
        builder.add_file_at(path: file_location)
      end
    end

    it "accepts a block to add files by their io" do
      client.create_transfer(message: 'Test transfer') do |builder|
        builder.add_file(name: File.basename(file_location), io: File.open(file_location, 'rb'))
      end
    end
  end

  describe "#complete_transfer"
  describe "#get_transfer"
end
