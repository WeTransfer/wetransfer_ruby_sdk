require "spec_helper"

describe "transfer integration" do
  around(:each) do |example|
    WebMock.allow_net_connect!
    example.run
    WebMock.disable_net_connect!
  end

  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch("WT_API_KEY")) }

  it "Convenience method create_transfer_and_upload_files does it all!" do
    transfer = client.create_transfer_and_upload_files(message: "test transfer") do |transfer|
      transfer.add_file(name: "small_file_with_io", size: 10, io: StringIO.new("#" * 10))
      transfer.add_file(io: File.open('Gemfile'))
    end

    # the transfer is (soon) ready to be downloaded. Time to inspect it:

    expect(transfer.files.map(&:name))
      .to match_array(%w[small_file_with_io Gemfile])
    expect(transfer.state)
      .to eq "processing"
    expect(transfer.url)
      .to match %r|https://we.tl/t-|
  end

  it "Create a client, a transfer, it uploads files and finalizes the transfer" do
    transfer = client.create_transfer(message: "test transfer") do |transfer|
      transfer.add_file(name: "small_file", size: 80)
      transfer.add_file(name: "small_file_with_io", size: 10, io: StringIO.new("#" * 10))
      transfer.add_file(name: "multi_chunk_big_image.jpg", io: File.open('spec/fixtures/Japan-01.jpg'))
    end

    expect(transfer.url.nil?)
      .to eq true

    expect(transfer.id.nil?).to eq false
    expect(transfer.state).to eq "uploading"
    expect(transfer.files.any? { |f| f.id.nil? }).to eq false

    transfer.upload_file(name: "small_file", io: StringIO.new("#" * 80))
    transfer.complete_file(name: "small_file")

    transfer.upload_file(name: "small_file_with_io")
    transfer.complete_file(name: "small_file_with_io")

    transfer.upload_file(name: "multi_chunk_big_image.jpg")
    transfer.complete_file(name: "multi_chunk_big_image.jpg")

    transfer.finalize

    expect(transfer.state).to eq "processing"

    # Your transfer is available (after processing) at `transfer.url`
    expect(transfer.url)
      .to match %r|https://we.tl/t-|
  end

  # # This test uses different transfer objects for the 4 different steps, so we isolate behavior
  # # of all cases as much as possible
  # it "handles diacritics in file names well", :focus do
  #   name_with_diacritics = "file-name-with-diacritics-äëüïö.jpg".freeze

  #   transfer = client.create_transfer(message: "test transfer") do |transfer|
  #     transfer.add_file(
  #       name: name_with_diacritics,
  #       size: 10,
  #       io: StringIO.new("#" * 10)
  #     )
  #   end

  #   transfer.upload_file(name: name_with_diacritics)
  #   transfer.complete_file(name: name_with_diacritics)
  #   transfer.finalize
  # end

  it "handles diacritics in file names well" do
    name_with_diacritics = "file-name-with-diacritics-äëüïö.jpg".freeze

    create_transfer = client.create_transfer(message: "test transfer") do |transfer|
      transfer.add_file(
        name: name_with_diacritics,
        size: 10,
      )
    end

    file_id = create_transfer.find_file(name_with_diacritics).id

    upload_file_transfer = client.find_transfer(create_transfer.id)
    upload_file_transfer.upload_file(id: file_id, io: StringIO.new("#" * 10))

    complete_file_transfer = client.find_transfer(create_transfer.id)
    complete_file_transfer.complete_file(id: file_id)

    finalize_transfer = client.find_transfer(create_transfer.id)
    finalize_transfer.finalize
  end
end
