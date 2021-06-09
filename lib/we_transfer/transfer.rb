# frozen_string_literal: true

module WeTransfer
  class Transfer
    class DuplicateFileNameError < ArgumentError; end
    class NoFilesAddedError < StandardError; end
    class FileMismatchError < StandardError; end

    extend Forwardable

    attr_reader :files, :id, :state, :url, :message

    def self.create(message:, communicator:, &block)
      transfer = new(message: message, communicator: communicator)

      transfer.persist(&block)
    end

    def initialize(message:, communicator:)
      @message = message
      @communicator = communicator
      @files = []
      @unique_file_names = Set.new
    end

    def persist
      yield(self) if block_given?
      raise NoFilesAddedError if @unique_file_names.empty?

      @communicator.persist_transfer(self)
    end

    # Add a file to a transfer.
    #
    # @param args   [Hash] (See WeTransferFile#initialize)
    #
    # @raise  [DuplicateFileNameError] Files should have a unique name -
    #         case insensitive - within a transfer. If that is not true, it
    #         will result in this error
    #
    # @return [WeTransfer::Transfer] self
    #
    # @see WeTransferFile#initialize
    #
    def add_file(**args)
      file = WeTransferFile.new(args)
      raise DuplicateFileNameError unless @unique_file_names.add?(file.name.downcase)

      @files << file
      self
    end

    # Upload the file. Convenience method for uploading the parts of the file in
    # chunks. This will upload all chunks in order, single threaded.
    #
    # @param  :name [String] The name used to add the file to the transfer
    # @param  :io [optional, String] The contents to be uploaded. If the file was
    #         added (See Transfer#add_file) including an io, this can be omitted.
    #         If the file was added including an io, *and* it is included in this
    #         call, the io from this invocation will be uploaded.
    # @param :file [optional, WeTransferFile] The file instance that will be
    #         uploaded.
    #
    # @raise  [WeTransfer::RemoteFile::NoIoError] Will be raised if the io does
    #         not meet the minimal requirements (see MiniIo.mini_io_able?)
    # @example
    #
    # @see MiniIo.mini_io_able?
    def upload_file(name:, io: nil, file: nil)
      file ||= find_file(name)
      put_io = io || file.io

      raise(
        WeTransfer::RemoteFile::NoIoError,
        "IO for file with name '#{name}' cannot be uploaded."
      ) unless WeTransfer::MiniIO.mini_io_able?(put_io)
      (1..file.multipart.chunks).each do |chunk|
        put_url = upload_url_for_chunk(file_id: file.id, chunk: chunk)
        chunk_contents = StringIO.new(put_io.read(file.multipart.chunk_size))
        chunk_contents.rewind

        @communicator.upload_chunk(put_url, chunk_contents)
      end
    end

    # Trigger the upload for all files. Since this method does not accept any io,
    # the files should be added (see #add_file) with a proper io object.
    #
    # @return [WeTransfer::Transfer] self
    def upload_files
      files.each do |file|
        upload_file(
          name: file.name,
          file: file
        )
      end
      self
    end

    def upload_url_for_chunk(file_id: nil, name: nil, chunk:)
      raise ArgumentError, "missing keyword: either name or file_id is required" unless file_id || name

      file_id ||= find_file(name).id
      @communicator.upload_url_for_chunk(id, file_id, chunk)
    end

    def complete_file(file: nil, name: file&.name, file_id: file&.id)
      raise ArgumentError, "missing keyword: either name or file is required" unless file || name || file_id

      file ||= find_file(name || file_id)
      @communicator.complete_file(id, file.id, file.multipart.chunks)
    end

    def complete_files
      files.each do |file|
        complete_file(
          name: file.name,
          file: file
        )
      end
      self
    end

    def finalize
      @communicator.finalize_transfer(self)
    end

    def as_persist_params
      {
        message: @message,
        files: @files.map(&:as_persist_params),
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

    # Find a file inside this transfer
    #
    # @param  [String] name_or_id, The name (as set by you) or the id (as returned)
    #         by WeTransfer Public API of the file.
    # @raise  [FileMismatchError] if a file with that name or id cannot be found for
    #         this transfer
    # @return [WeTransferFile] The file you requested
    #
    def find_file(name_or_id)
      @found_files ||= Hash.new do |h, name_or_id|
        h[name_or_id] = files.find { |file| [file.name, file.id].include? name_or_id }
      end

      raise FileMismatchError unless @found_files[name_or_id]
      @found_files[name_or_id]
    end
  end
end
