require 'spec_helper'

describe WeTransfer::Client::Transfers do
  let(:test_logger) do
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end

  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  let(:upload_file) { 'spec/files/Japan-02.jpg' }

  let(:created_transfer) do
    client.create_transfer(message: 'Test transfer') do |builder|
      builder.add_file(name: File.basename(upload_file), io: File.open(upload_file, 'rb'))
    end
  end

  describe "#create_transfer" do
    it "is needed to add a file" do
      expect { client.create_transfer(message: "Transfer name") }
        .to raise_error(ArgumentError, /^No files were added/)
    end

    it "accepts a block to add files by their location" do
      client.create_transfer(message: 'Test transfer') do |builder|
        builder.add_file_at(path: upload_file)
      end
    end

    it "accepts a block to add files by their io" do
      client.create_transfer(message: 'Test transfer') do |builder|
        builder.add_file(name: File.basename(upload_file), io: File.open(upload_file, 'rb'))
      end
    end
  end

  describe "#complete_transfer"
  describe "#get_transfer"
end
