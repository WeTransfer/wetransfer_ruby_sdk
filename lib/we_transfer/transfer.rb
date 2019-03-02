module WeTransfer
  class Transfer
    class DuplicateFileNameError < ArgumentError; end
    class NoFilesAddedError < StandardError; end
    class FileMismatchError < StandardError; end

    extend Forwardable

    attr_reader :files, :id, :state, :url, :message

    class << self
      extend Forwardable
      def_delegator Communication, :find_transfer, :find
    end

    def self.create(message:, &block)
      transfer = new(message: message)

      transfer.persist(&block)
    end

    def initialize(message:)
      @message = message
      @files = []
      @unique_file_names = Set.new
    end

    def persist
      yield(self) if block_given?
      raise NoFilesAddedError if @unique_file_names.empty?

      Communication.persist_transfer(self)
    end

    # Add one or more files to a transfer, so a transfer can be created over the
    # WeTransfer public API
    #
    # @params name [String] (nil) the name of the file
    #
    # @returns self [WeTransfer::Client]
    def add_file(**args)
      file = WeTransferFile.new(args)
      raise DuplicateFileNameError unless @unique_file_names.add?(file.name.downcase)

      @files << file
      self
    end

    def upload_file(name:, io: nil, file: nil)
      file ||= find_file_by_name(name)
      put_io = io || file.io

      raise(
        WeTransfer::RemoteFile::NoIoError,
        "IO for file with name '#{name}' cannot be uploaded."
      ) unless WeTransfer::MiniIO.mini_io_able?(put_io)

      (1..file.multipart.chunks).each do |chunk|
        put_url = upload_url_for_chunk(name: name, chunk: chunk)
        chunk_contents = StringIO.new(put_io.read(file.multipart.chunk_size))
        chunk_contents.rewind

        Communication.upload_chunk(put_url, chunk_contents)
      end
    end

    #
    def upload_files
      files.each do |file|
        upload_file(
          name: file.name,
          file: file
        )
      end
    end

    def upload_url_for_chunk(name:, chunk:)
      file_id = find_file_by_name(name).id
      Communication.upload_url_for_chunk(id, file_id, chunk)
    end

    def complete_file(name:, file: nil)
      file ||= find_file_by_name(name)
      Communication.complete_file(id, file.id, file.multipart.chunks)
    end

    def complete_files
      files.each do |file|
        complete_file(
          name: file.name,
          file: file
        )
      end
    end

    def finalize
      Communication.finalize_transfer(self)
    end

    def as_request_params
      {
        message: @message,
        files: @files.map(&:as_request_params),
      }
    end

    def to_json
      to_h.to_json
    end

    def to_h
      prepared = %i[id state url message].each_with_object({}) do |prop, memo|
        memo[prop] = send(prop)
      end

      prepared[:files] = files.map(&:to_h)
      prepared
    end

    def find_file_by_name(name)
      @found_files ||= Hash.new do |h, name|
        h[name] = files.find { |file| file.name == name }
      end

      raise FileMismatchError unless @found_files[name]
      @found_files[name]
    end
  end
end
