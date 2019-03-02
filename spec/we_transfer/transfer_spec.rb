require "spec_helper"

describe WeTransfer::Transfer do
  let!(:authentication_stub) {
    stub_request(:post, "#{WeTransfer::Communication::API_URL_BASE}/v2/authorize")
    .to_return(status: 200, body: {token: "fake-test-token"}.to_json, headers: {})
  }

  let!(:create_transfer_stub) do
    stub_request(:post, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers").
    to_return(
      status: 200,
      body: {
        success: true,
        id: "24cd3f4ccf15232e5660052a3688c03f20190221200022",
        state: "uploading",
        message: "test transfer",
        url: nil,
        files: files_stub,
        expires_at: "2019-02-28T20:00:22Z"
      }.to_json,
      headers: {},
    )
  end

  let!(:find_transfer_stub) do
    stub_request(:get, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers/fake-transfer-id").
    to_return(
      status: 200,
      body: {
        id: "24cd3f4ccf15232e5660052a3688c03f20190221200022",
        state: "uploading",
        message: "test transfer",
        url: nil,
        files: files_stub,
        expires_at: "2019-02-28T20:00:22Z"
      }.to_json,
      headers: {},
    )
  end

  let(:files_stub) {
    [
      {
        id: "fake_file_id",
        name: "test file",
        size: 8,
        multipart: {
          part_numbers: 1,
          chunk_size: 8
        },
        type: "file",
      }
    ]
  }

  describe ".create" do
    it "instantiates a transfer" do
      expect(described_class)
        .to receive(:new)
        .with(message: "through .create")
        .and_call_original

      begin
        described_class.create(message: "through .create")
      rescue WeTransfer::Transfer::NoFilesAddedError
        # TODO: a rescue that would break an initializer is kinda moot in an instantiation
        #  test ¯\_(ツ)_/¯
      end
    end

    it "calls #persist on the instantiated transfer" do
      add_file_lambda = ->(transfer) { transfer.add_file(name: "test file", size: 8) }

      expect_any_instance_of(described_class)
        .to receive(:persist) do |*_args, &block|
          expect(add_file_lambda).to be(block)
        end
        .and_call_original

      described_class.create(message: "through .create", &add_file_lambda)
    end
  end

  describe ".find" do
    it "GETs the transfer by its id" do
      described_class.find("fake-transfer-id")

      expect(find_transfer_stub)
        .to have_been_requested
    end

    it "sets up files" do
      transfer = described_class.find("fake-transfer-id")
      {
        id: "fake_file_id",
        name: "test file",
      }.each do |attr, value|
        expect(transfer.files.first.send(attr)).to eq value
      end
    end
  end

  describe "initialize" do
    it "passes with a message" do
      expect { described_class.new(message: "test transfer") }
        .to_not raise_error
    end

    it "fails without a message" do
      expect { described_class.new }
        .to raise_error ArgumentError, %r|message|
    end
  end

  describe "#files" do
    it "is a getter for @files" do
      transfer = described_class.new(message: "test transfer")
      transfer.instance_variable_set :@files, "this is a fake"

      expect(transfer.files).to eq "this is a fake"
    end
  end

  describe "#persist" do
    context "adding multiple files, using a block" do
      let(:files_stub) {
        [
          {
            id: "fake_file_id",
            name: "file1",
            size: 8,
            multipart: {
              part_numbers: 1,
              chunk_size: 8
            },
            type: "file",
          }, {
            id: "f740463d4e995720280fa08efe1911ef20190221200022",
            name: "file2",
            size: 8,
            multipart: {
              part_numbers: 1,
              chunk_size: 8
            },
            type: "file",
          }
        ]
      }

      it "works on a transfer without any files" do
        transfer = described_class.new(message: "test transfer")

        transfer.persist do |transfer|
          transfer.add_file(name: "file1", size: 8)
          transfer.add_file(name: "file2", size: 8)
        end

        expect(create_transfer_stub)
          .to have_been_requested
      end

      it "can be used  on a transfer that already has some files" do
        transfer = described_class.new(message: "test transfer")
        transfer.add_file(name: "file1", size: 8)

        transfer.persist { |transfer| transfer.add_file(name: "file2", size: 8) }

        expect(create_transfer_stub)
          .to have_been_requested
      end
    end

    context "not adding files, using a block" do
      it "can create a remote transfer if the transfer already had one" do
        transfer = described_class.new(message: "test transfer")
        transfer.add_file(name: "test file", size: 8)

        transfer.persist

        expect(create_transfer_stub)
          .to have_been_requested
      end
    end

    context "with files" do
      it "can create a remote transfer if the transfer "
    end
    context "with files" do
      it "creates a remote transfer"
      it "exposes new methods on the WeTransferFile instances"
    end
  end

  describe "#add_file" do
    subject(:transfer) do
      described_class.new(message: "test transfer") do |transfer|
        # this block is used to add files using
        # transfer.add_file(name:, size:, io:)
      end
    end

    let(:file_params)  { { name: "test file", size: :bar, io: :baz } }

    it "can be called with only a name and a size" do
      expect { transfer.add_file(name: "test file", size: :bar) }
        .to_not raise_error
    end

    context "when called with only an io" do
      it "does work if the io provides a name and a size" do
        transfer.add_file(io: File.open("Gemfile"))
      end

      it "doesn't work if the io has no name" do
        nameless_io = StringIO.new("I have no name, but a size I have")
        expect { transfer.add_file(io: nameless_io) }
          .to raise_error(ArgumentError, %r|name.*size.* or io should provide it|)
      end
    end

    it "can be called with an io, a name and a size" do
      io = File.open("Gemfile")
      expect { transfer.add_file(name: "Gemfile", size: 20, io: io) }
        .to_not raise_error
    end

    it "does not accept duplicate file names, case insensitive" do
      file_a_params = { name: "same", size: 416 }
      file_b_params = { name: "same", size: 501 }
      file_c_params = { name: "SAME", size: 816 }

      transfer.add_file(file_a_params)

      expect { transfer.add_file(file_b_params) }
        .to raise_error(WeTransfer::Transfer::DuplicateFileNameError)

      expect { transfer.add_file(file_c_params) }
        .to raise_error(WeTransfer::Transfer::DuplicateFileNameError)
    end

    context "WeTransferFile interaction" do
      let(:fake_transfer_file) { instance_double(WeTransfer::WeTransferFile, name: "fake") }

      it "instantiates a TransferFile" do
        expect(WeTransfer::WeTransferFile)
          .to receive(:new)
          .and_return(fake_transfer_file)

        transfer.add_file(file_params)
      end

      it "adds the instantiated TransferFile to the @files collection" do
        allow(WeTransfer::WeTransferFile)
          .to receive(:new)
          .and_return(fake_transfer_file)

        transfer.add_file(file_params)

        expect(subject.instance_variable_get(:@files))
          .to eq [fake_transfer_file]
      end

      it "returns self" do
        allow(WeTransfer::WeTransferFile)
          .to receive(:new)
          .and_return(fake_transfer_file)

        expect(transfer.add_file(file_params)).to eq transfer
      end
    end
  end

  describe "#upload_file" do
    it "should be called with :name" do
      transfer = described_class.new(message: "test transfer")
      transfer.add_file(name: "test file", size: 8)

      expect { transfer.upload_file }
        .to raise_error ArgumentError, %r|name|
    end

    context "without io keyword param" do
      it "works if the WeTransferFile instance has an io" do
        transfer = described_class.new(message: "test transfer")
        transfer.add_file(name: "test file", size: 8, io: StringIO.new("12345678"))
        transfer.persist

        allow(transfer)
          .to receive(:upload_url_for_chunk)
          .with(name: "test file", chunk: kind_of(Numeric))
          .and_return("https://signed.url/123")

        stub_request(:put, "https://signed.url/123")
          .to_return(status: 200, body: "", headers: {})

        expect { transfer.upload_file(name: "test file") }
          .to_not raise_error
      end

      it "breaks if the WeTransferFile instance does not have an io" do
        transfer = described_class.new(message: "test transfer")
        transfer.add_file(name: "test file", size: 8)

        expect { transfer.upload_file(name: "test file") }
          .to raise_error WeTransfer::RemoteFile::NoIoError, %r|'test file' cannot be uploaded|
      end

      it "invokes :upload_url_for_chunk to obtain a PUT url" do
        transfer = described_class.new(message: "test transfer")
        transfer.add_file(name: "test file", size: 8, io: StringIO.new("12345678"))
        transfer.persist

        stub_request(:put, "https://signed.url/123")
          .to_return(status: 200, body: "", headers: {})

        expect(transfer)
          .to receive(:upload_url_for_chunk)
          .with(name: "test file", chunk: kind_of(Numeric))
          .and_return("https://signed.url/123")

        transfer.upload_file(name: "test file")
      end
    end

    context "uploads each chunk" do
      it "upload is triggered once if the io smaller than the server's chunk size" do
        transfer = described_class.new(message: "test transfer")

        file_name = "test file"
        contents = "12345678"

        upload_request_stub = stub_request(:put, "https://signed.url/123")
          .with(body: contents)

        transfer.add_file(name: file_name, io: StringIO.new(contents))
        transfer.persist

        expect(transfer)
          .to receive(:upload_url_for_chunk)
          .with(name: file_name, chunk: 1)
          .and_return("https://signed.url/123")
          .once

        transfer.upload_file(name: file_name)

        expect(upload_request_stub).to have_been_requested
      end

      it "upload is triggered twice if the io is 1.5 times the server's chunk size" do
        remove_request_stub(create_transfer_stub)

        file_name = "test file"
        file_size = 7_500_000
        contents = "-" * file_size

        stub_request(:post, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers")
          .to_return(
            status: 200,
            body: {
              success: true,
              id: "04a1828e9a193adacb3ea110cdcf773320190226161412",
              state: "uploading",
              message: "test transfer",
              url: nil,
              files: [
                {
                  id: "3a2b2c5e01657dbe09e104aa5fdd01f020190226161412",
                  name: file_name,
                  size: file_size,
                  multipart: {
                    part_numbers: 2,
                    chunk_size: 5242880
                  },
                  type: "file"
                }
              ],
              expires_at: "2019-03-05T1614:12Z"
            }.to_json,
            headers: {}
          )

        transfer = described_class.new(message: "test transfer")

        expect(transfer)
          .to receive(:upload_url_for_chunk)
          .with(name: file_name, chunk: kind_of(Numeric))
          .and_return("https://signed.url/big-chunk-1", "https://signed.url/big-chunk-2")

        put_1 = stub_request(:put, "https://signed.url/big-chunk-1")
        put_2 = stub_request(:put, "https://signed.url/big-chunk-2")

        transfer.add_file(name: file_name, size: file_size, io: StringIO.new(contents))
        transfer.persist

        transfer.upload_file(name: file_name)
        expect(put_1).to have_been_requested
        expect(put_2).to have_been_requested
      end
    end
  end

  describe "#upload_url_for_chunk" do
    it "does something"
  end

  describe "#complete_file" do
    it "works" do
      transfer = described_class.new(message: "test transfer")
      transfer.add_file(name: "test file", size: 8)
      transfer.persist

      allow(transfer)
        .to receive(:id)
        .and_return("transfer_id")

      allow(transfer.files.first)
        .to receive(:id)
        .and_return("file_id")

      upload_complete_stub = stub_request(:put, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers/transfer_id/files/file_id/upload-complete").
        with(
          body: { part_numbers: 1 }.to_json,
        )
        .to_return(
          status: 200,
          body: {
            success: true,
            id: "26a8bb18b75d8c67c744cdf3655c3fdd20190227112811",
            retries: 0,
            name: "test_file_1",
            size: 10,
            chunk_size: 5242880
          }.to_json,
          headers: {}
        )

      transfer.complete_file(name: "test file")

      expect(upload_complete_stub).to have_been_requested
    end
  end

  describe "#finalize" do
    subject(:transfer) do
      WeTransfer::Transfer
        .new(message: "test transfer")
        .add_file(name: "test file", size: 30)
    end

    let!(:finalize_transfer_stub) do
      stub_request(:put, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers/fake-transfer-id/finalize").
        to_return(
          status: 200,
          body: {
            success: true,
            id: "fake-transfer-id",
            state: "processing",
            message: "test transfer",
            url: "https://we.tl/t-c5mHAyq1iO",
            files: [
              {
                id: "b40157b36830c0ca37059af5b054a45b20190225084239",
                name: "test file",
                size: 30,
                multipart: {
                  part_numbers: 1,
                  chunk_size: 30
                },
                type: "file"
              }
            ],
            expires_at: "2019-03-04T08:42:39Z"
          }.to_json,
          headers: {},
        )
    end

    before { allow(transfer).to receive(:id).and_return("fake-transfer-id") }

    it "PUTs to the finalize endpoint" do
      transfer.finalize

      expect(finalize_transfer_stub).to have_been_requested
    end

    it "gets a new status" do
      expect(transfer.state).to be_nil
      transfer.finalize
      expect(transfer.state).to eq "processing"
    end

    it "url?"
  end
end
