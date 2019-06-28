require "spec_helper"

describe WeTransfer::Transfer do
  let(:communicator) { instance_double(WeTransfer::Communicator) }

  describe "Error classes" do
    it "NothingToUploadError is a subtype of ArgumentError" do
      expect(
        WeTransfer::Transfer::NothingToUploadError
          .new
          .is_a?(ArgumentError)
      ).to eq true
    end
  end

  describe ".create" do
    it "instantiates a transfer" do
      expect(described_class)
        .to receive(:new)
        .with(message: "test transfer", communicator: communicator)
        .and_call_original

      begin
        described_class.create(
          message: "test transfer",
          communicator: communicator
        )
      rescue WeTransfer::Transfer::NoFilesAddedError
        # We're rescuing here: This tests just that :create calls the initializer.
      end
    end

    it "calls #persist on the instantiated transfer" do
      add_file_lambda = ->(transfer) { transfer.add_file(name: "test file", size: 8) }

      allow(communicator)
        .to receive(:persist_transfer)

      expect_any_instance_of(described_class)
        .to receive(:persist) do |*_args, &block|
          expect(add_file_lambda).to be(block)
        end
        .and_call_original

      described_class.create(
        message: "fake transfer",
        communicator: communicator,
        &add_file_lambda
      )
    end
  end

  describe ".find" do
    before { skip("This interface is removed") }

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
    it "needs a :message and a :communicator kw argument" do
      expect {
        described_class.new(
          message: "test transfer",
          communicator: communicator
        )
      }.to_not raise_error
    end

    it "fails without a :message param" do
      expect { described_class.new(communicator: communicator) }
        .to raise_error ArgumentError, %r|message|
    end

    it "fails without a :communicator param" do
      expect { described_class.new(message: "test transfer") }
        .to raise_error ArgumentError, %r|communicator|
    end
  end

  describe "#files" do
    it "is a getter for @files" do
      transfer = described_class.new(
        message: "test transfer",
        communicator: communicator
      )

      transfer.instance_variable_set :@files, "this is a fake"

      expect(transfer.files).to eq "this is a fake"
    end
  end

  describe "#persist" do
    subject(:transfer) {
      described_class.new(
        message: "test transfer",
        communicator: communicator
      )
    }

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
        # transfer = described_class.new(message: "test transfer")

        expect(communicator)
          .to receive(:persist_transfer)

        transfer.persist do |transfer|
          transfer.add_file(name: "file1", size: 8)
          transfer.add_file(name: "file2", size: 8)
        end
      end

      it "can be used on a transfer that already has some files" do
        # transfer = described_class.new(message: "test transfer")
        transfer.add_file(name: "file1", size: 8)

        expect(communicator)
          .to receive(:persist_transfer)

        transfer.persist { |transfer| transfer.add_file(name: "file2", size: 8) }
      end
    end

    context "not adding files, using a block" do
      it "can create a remote transfer if the transfer already had one" do
        # transfer = described_class.new(message: "test transfer")
        transfer.add_file(name: "test file", size: 8)

        expect(communicator)
          .to receive(:persist_transfer)

        transfer.persist
      end
    end
  end

  describe "#add_file" do
    subject(:transfer) do
      described_class.new(
        message: "test transfer",
        communicator: communicator
      )
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
    subject(:transfer) do
      described_class.new(
        message: "test transfer",
        communicator: communicator
      )
    end

    context "called without :file, without :id, without :io params" do
      it "raises" do
        expect { transfer.upload_file }
          .to raise_error WeTransfer::Transfer::NothingToUploadError, %r|file.*id.*io|
      end
    end

    context "called with :id and with :io params" do
      it "doesn't raise" do
        expect { transfer.upload_file(id: 'fake', io: StringIO.new("a")) }
          .to_not raise_error WeTransfer::Transfer::NothingToUploadError
      end
    end

    context "called with :file param" do
      it "doesn't raise" do
        expect { transfer.upload_file(file: double(WeTransfer::WeTransferFile)) }
          .to_not raise_error WeTransfer::Transfer::NothingToUploadError
      end
    end

    context "without io keyword param," do
      context "if the WeTransferFile instance has an io" do
        it "calls upload_chunk on the communicator" do
          transfer.add_file(name: "test file", size: 8, io: StringIO.new("12345678"))

          # transfer.persist # does a network call
          # fake-persist the transfer so we can spec the complete_file run
          multipart = instance_double(
            WeTransfer::RemoteFile::Multipart,
            chunks: 1,
            chunk_size: 20
          )
          transfer.instance_variable_set :@id, 'fake-transfer-id'
          transfer.files.each do |f|
            f.instance_variable_set :@id, 'fake-file-id'
            f.instance_variable_set :@multipart, multipart
          end

          allow(transfer)
            .to receive(:upload_url_for_chunk)
            .with(file_id: "fake-file-id", chunk: kind_of(Numeric))
            .and_return("https://fake.upload.url/123")

          expect(communicator)
            .to receive(:upload_chunk)
            .with("https://fake.upload.url/123", kind_of(StringIO))

          transfer.upload_file(id: "fake-file-id")
        end

        it "invokes :upload_url_for_chunk to obtain a PUT url" do
          transfer.add_file(name: "test file", size: 8, io: StringIO.new("12345678"))

          # transfer.persist # does a network call
          # fake-persist the transfer so we can spec the complete_file run
          multipart = instance_double(
            WeTransfer::RemoteFile::Multipart,
            chunks: 1,
            chunk_size: 20
          )
          transfer.instance_variable_set :@id, 'fake-transfer-id'
          transfer.files.each do |f|
            f.instance_variable_set :@id, 'fake-file-id'
            f.instance_variable_set :@multipart, multipart
          end

          allow(communicator)
            .to receive(:upload_chunk)

          expect(transfer)
            .to receive(:upload_url_for_chunk)
            .with(file_id: "fake-file-id", chunk: 1)

          transfer.upload_file(id: "fake-file-id")
        end
      end
    end

    context "uploads each chunk" do
      it "upload is triggered once if the io is smaller than the server's chunk size" do
        transfer.add_file(name: "test file", io: StringIO.new("12345678"))

        # transfer.persist # does a network call
        # fake-persist the transfer so we can spec the complete_file run
        multipart = instance_double(
          WeTransfer::RemoteFile::Multipart,
          chunks: 1,
          chunk_size: 8,
        )
        transfer.instance_variable_set :@id, 'fake-transfer-id'
        transfer.files.each do |f|
          f.instance_variable_set :@id, 'fake-file-id'
          f.instance_variable_set :@multipart, multipart
        end

        allow(communicator)
          .to receive(:upload_chunk)

        expect(transfer)
          .to receive(:upload_url_for_chunk)
          .with(file_id: 'fake-file-id', chunk: 1)
          .and_return("https://signed.url/123")
          .once

        transfer.upload_file(id: 'fake-file-id')
      end

      it "upload is triggered twice if the io is has 2 chunks" do
        file_name = "test file"
        file_size = 1_000
        contents = "-" * file_size

        transfer.add_file(name: file_name, size: file_size, io: StringIO.new(contents))
        # transfer.persist # does a network call
        # fake-persist the transfer so we can spec the complete_file run
        multipart = instance_double(
          WeTransfer::RemoteFile::Multipart,
          chunks: 2,
          chunk_size: 750 # not the right number, but we allow the server to set it
        )
        transfer.instance_variable_set(:@id, 'fake-transfer-id')

        transfer.files.each do |f|
          f.instance_variable_set :@id, 'fake-file-id'
          f.instance_variable_set :@multipart, multipart
        end

        expect(transfer)
          .to receive(:upload_url_for_chunk)
          .with(file_id: 'fake-file-id', chunk: kind_of(Numeric))
          .and_return("https://fake.upload.url/big-chunk-1", "https://fake.upload.url/big-chunk-2")

        expect(communicator)
          .to receive(:upload_chunk)
          .with(%r|https://fake.upload.url/big-chunk-\d|, kind_of(StringIO))
          .exactly(2).times

        transfer.upload_file(id: 'fake-file-id')
      end
    end
  end

  describe "#upload_files" do
    subject(:transfer) do
      described_class.new(
        message: "test transfer",
        communicator: communicator
      )
    end

    it "invokes :upload_file for each file in the files collection" do
      file_factory = Struct.new(:id)
      transfer.instance_variable_set(:@files, 2.times.map { |n| file_factory.new("file-#{n}") })

      expect(transfer)
        .to receive(:upload_file)
        .with(hash_including(:file, :id))
        .twice

      transfer.upload_files
    end
  end

  describe "#upload_url_for_chunk" do
    subject(:transfer) do
      described_class.new(
        message: "test transfer",
        communicator: communicator
      )
    end

    it "must be invoked with a :chunk kw param" do
      expect { transfer.upload_url_for_chunk }
        .to raise_error(ArgumentError, %r|chunk|)
    end

    it "must be invoked with a :file_id or :name kw param" do
      expect { transfer.upload_url_for_chunk(chunk: :foo) }
        .to raise_error(ArgumentError, %r|name.*file_id|)

      allow(communicator)
        .to receive(:upload_url_for_chunk)

      transfer.add_file(name: 'bar', size: 8)
      transfer.files.first.instance_variable_set :@id, 'baz'

      expect { transfer.upload_url_for_chunk(chunk: :foo, file_id: 'baz') }
        .not_to raise_error
    end

    it "invokes :upload_url_for_chunk on the communicator" do
      allow(transfer)
        .to receive(:id)
        .and_return 'fake-transfer-id'

      file = Struct.new(:id).new('fake-file-id')
      chunk = 3

      expect(communicator)
        .to receive(:upload_url_for_chunk)
        .with(transfer.id, file.id, chunk)

      transfer.upload_url_for_chunk(file_id: file.id, chunk: chunk)
    end
  end

  describe "#complete_file"  do
    subject(:transfer) do
      described_class.new(
        message: "test transfer",
        communicator: communicator
      )
    end

    let(:file) {
      instance_double(
        WeTransfer::WeTransferFile,
        id: 'fake-file-id',
        name: 'meh',
        multipart: multipart
      )
    }

    let(:multipart) {
      instance_double(
        WeTransfer::RemoteFile::Multipart,
        chunks: 1,
        chunk_size: 20
      )
    }

    it "can be invoked with a :name kw param" do
      transfer.add_file(name: 'meh', size: 20)

      # fake-persist the transfer so we can spec the complete_file run
      transfer.instance_variable_set :@id, 'fake-transfer-id'
      transfer.files.each do |f|
        f.instance_variable_set :@id, 'fake-file-id'
        f.instance_variable_set :@multipart, multipart
      end

      expect(communicator)
        .to receive(:complete_file)

      transfer.complete_file(id: 'fake-file-id')
    end

    it "can be invoked with a :file kw param" do
      transfer.add_file(name: file.name, size: 12)

      transfer.instance_variable_set :@id, 'fake-transfer-id'
      transfer.files.each do |f|
        f.instance_variable_set :@id, 'fake-file-id'
        f.instance_variable_set :@multipart, multipart
      end

      allow(communicator)
        .to receive(:complete_file)

      transfer.complete_file(file: file)
    end

    it "if invoked with both a :id or a :file param, the :file takes precedence" do
      allow(communicator)
        .to receive(:complete_file)
      expect(transfer)
        .to_not receive(:find_file)

      transfer.complete_file(id: 'fake-file-id', file: file)
    end

    it "needs to be invoked with either a :name or a :file kw param" do
      expect { transfer.complete_file }
        .to raise_error(ArgumentError, %r|name.*file|)
    end
  end

  describe "#complete_files" do
    subject(:transfer) do
      described_class.new(
        message: "test transfer",
        communicator: communicator
      )
    end

    let(:file_factory) { Struct.new(:name) }

    it "invokes :complete_file for each file in the files collection" do
      transfer.instance_variable_set(:@files, 2.times.map { |n| file_factory.new("file-#{n}") })

      expect(transfer)
        .to receive(:complete_file)
        .with(hash_including(:file, :name))
        .twice

      transfer.complete_files
    end
  end

  describe "#finalize" do
    subject(:transfer) do
      WeTransfer::Transfer
        .new(
          message: "test transfer",
          communicator: communicator,
        )
        .add_file(name: "test file", size: 30)
    end

    before { allow(transfer).to receive(:id).and_return("fake-transfer-id") }

    it "invokes :finalize_transfer on the communicator" do
      expect(communicator)
        .to receive(:finalize_transfer)
        .with(transfer)

      transfer.finalize
    end
  end

  describe "#as_persist_params" do
    subject(:transfer) do
      described_class.new(
        message: "test transfer",
        communicator: communicator
      )
    end

    it "returns a hash with the right values for :message and :files" do
      expected = { message: "test transfer", files: [] }
      expect(transfer.as_persist_params)
        .to eq expected
    end

    it "invokes :as_persist_params on each member of files" do
      transfer.add_file(name: "test file 1", size: 8)
      transfer.add_file(name: "test file 2", size: 8)

      transfer.files.each do |file|
        expect(file)
          .to receive(:as_persist_params)
      end
      transfer.as_persist_params
    end
  end

  describe "#to_h" do
    let(:transfer) { described_class.new(message: 'test transfer', communicator: nil) }
    let(:file_stub_1) { [instance_double(WeTransfer::WeTransferFile, name: 'foo', size: 8)] }

    it "has keys and values for id, state, url, message and files" do
      allow(file_stub_1)
        .to receive(:to_h)
        .and_return('fake-file-to_h')

      allow(transfer)
        .to receive(:files)
        .and_return([file_stub_1])

      allow(transfer)
        .to receive(:id)
        .and_return('fake-id')

      allow(transfer)
        .to receive(:state)
        .and_return('fake-state')

      allow(transfer)
        .to receive(:url)
        .and_return('fake-url')

      expected = {
        id: "fake-id",
        state: "fake-state",
        url: "fake-url",
        message: "test transfer",
        files: ["fake-file-to_h"]
      }

      expect(transfer.to_h)
        .to match(expected)
    end

    it "calls :to_h on all files" do
      file_stub_2 = instance_double(WeTransfer::WeTransferFile, name: 'bar', size: 8)

      allow(transfer)
        .to receive(:files)
        .and_return([file_stub_1, file_stub_2])

      expect(file_stub_1)
        .to receive(:to_h)

      expect(file_stub_2)
        .to receive(:to_h)

      transfer.to_h
    end
  end

  describe "#to_json" do
    it "converts the results of #to_h" do
      transfer = described_class.new(message: 'test transfer', communicator: nil)

      transfer_hash = { "foo" => "bar" }

      allow(transfer)
        .to receive(:to_h)
        .and_return(transfer_hash)

      expect(JSON.parse(transfer.to_json))
        .to eq(transfer_hash)
    end
  end
end
