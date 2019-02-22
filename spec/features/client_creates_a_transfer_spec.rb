require "spec_helper"

describe "transfer integration" do
  around do |example|
    WebMock.allow_net_connect!
    example.run
    WebMock.disable_net_connect!
  end

  it "Create a client, a transfer, it uploads files and finalizes the transfer" do
    client = WeTransfer::Client.new(api_key: ENV.fetch("WT_API_KEY"))

    client.create_transfer(message: "test transfer") do |transfer|
      transfer.add_file(name: "small_file", size: 80)
      transfer.add_file(name: "small_file_with_io", size: 10, io: StringIO.new("#" * 10))
      transfer.add_file(name: "multi_chunk_big_file", io: File.open('spec/fixtures/Japan-01.jpg'))
    end

    transfer = client.transfer

    transfer.to_json

    expect(transfer.url)
      .to be_nil

    expect(transfer.id.nil?).to eq false
    expect(transfer.state).to eq "uploading"
    expect(transfer.files.none? { |f| f.id.nil? }).to eq true

    transfer.upload_file(name: "small_file", io: StringIO.new("#" * 80))
    transfer.complete_file(name: "small_file")

    transfer.upload_file(name: "small_file_with_io")
    transfer.complete_file(name: "small_file_with_io")

    transfer.upload_file(name: "multi_chunk_big_file")
    transfer.complete_file(name: "multi_chunk_big_file")

    transfer.finalize

    expect(transfer.state).to eq "processing"

    # Your transfer is available (after processing) at `transfer.url`
    expect(transfer.url)
      .to match %r|https://we.tl/t-|
  end
end
