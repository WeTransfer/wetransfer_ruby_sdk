require 'spec_helper'

describe WeTransfer::Transfer do
  let!(:authentication_stub) {
    stub_request(:post, "#{WeTransfer::CommunicationHelper::API_URI_BASE}/v2/authorize")
    .to_return(status: 200, body: {token: 'fake-test-token'}.to_json, headers: {})
  }

  let!(:create_transfer_stub) do
    stub_request(:post, "#{described_class::API_URI_BASE}/v2/transfers").
    to_return(
      status: 200,
      body: {
        success: true,
        id: "24cd3f4ccf15232e5660052a3688c03f20190221200022",
        state: "uploading",
        message: "test transfer",
        url: nil,
        files: [
          {
            id: "f740463d4f995720280fa08efe1911ef20190221200022",
            name: "test_file",
            size: 8,
            multipart: {
              part_numbers: 1,
              chunk_size: 8
            },
            type: "file",
          },
        ],
        expires_at: "2019-02-28T20:00:22Z"
      }.to_json,
      headers: {},
    )
  end

  describe ".create" do
    it "instantiates a transfer" do
      expect(described_class)
        .to receive(:new)
        .with(message: 'through .create')
        .and_call_original

      begin
        described_class.create(message: 'through .create')
      rescue WeTransfer::Transfer::NoFilesAddedError
      end
    end

    it "calls #persist on the instantiated transfer" do
      add_file_lambda = ->(transfer) { transfer.add_file(name: 'foo', size: 8) }

      expect_any_instance_of(described_class)
        .to receive(:persist) do |*_args, &block|
          expect(add_file_lambda).to be(block)
        end
        .and_call_original

      described_class.create(message: 'through .create', &add_file_lambda)
    end
  end

  describe "initialize" do
    it "passes with a message" do
      expect { described_class.new(message: 'test transfer') }
        .to_not raise_error
    end

    it "fails without a message" do
      expect { described_class.new }
        .to raise_error ArgumentError, %r|message|
    end
  end

  describe "#persist" do
    context "adding files, using a block" do
      it "works on a transfer without any files" do
        transfer = described_class.new(message: "test transfer")

        transfer.persist { |transfer| transfer.add_file(name: 'test_file', size: 8) }

        expect(create_transfer_stub)
          .to have_been_requested
        end

      it "works on a transfer that already has some files" do
        transfer = described_class.new(message: 'test transfer') do |t|
          t.add_file(name: 'file1', size: 8)
        end

        transfer.persist { |transfer| transfer.add_file(name: 'file2', size: 8) }

        expect(create_transfer_stub)
          .to have_been_requested
      end
    end

    context "not adding files, using a block" do
      it "can create a remote transfer if the transfer already had one" do
        transfer = described_class.new(message: 'test transfer')
        transfer.add_file(name: 'file1', size: 8)

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
      described_class.new(message: 'test transfer') do |transfer|
        # this block is used to add files using
        # transfer.add_file(name:, size:, io:)
      end
    end

    let(:file_params)  { { name: :foo, size: :bar, io: :baz } }

    it "can be called with only a name and a size" do
      expect { transfer.add_file(name: :foo, size: :bar) }
        .to_not raise_error
    end

    context "when called with only an io" do
      it "does work if the io provides a name and a size" do
        transfer.add_file(io: File.open('Gemfile'))
      end

      it "doesn't work if the io has no name" do
        nameless_io = StringIO.new('I have no name, but a size I have')
        expect { transfer.add_file(io: nameless_io) }
          .to raise_error(ArgumentError, %r|name.*size.* or io should provide it|)
      end
    end

    it "can be called with an io, a name and a size" do
      io = File.open('Gemfile')
      expect { transfer.add_file(name: 'Gemfile', size: 20, io: io) }
        .to_not raise_error
    end

    it "does not accept duplicate file names, case insensitive" do
      file_a_params = { name: 'same', size: 416 }
      file_b_params = { name: 'same', size: 501 }
      file_c_params = { name: 'SAME', size: 816 }

      transfer.add_file(file_a_params)

      expect { transfer.add_file(file_b_params) }
        .to raise_error(WeTransfer::Transfer::DuplicateFileNameError)

      expect { transfer.add_file(file_c_params) }
        .to raise_error(WeTransfer::Transfer::DuplicateFileNameError)
    end

    context "WeTransferFile interaction" do
      let(:fake_transfer_file) { instance_double(WeTransfer::WeTransferFile, name: 'fake') }

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
end
