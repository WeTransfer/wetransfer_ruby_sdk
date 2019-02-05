module WeTransfer
  class RemoteTransfer
    attr_reader :files, :url, :state, :id

    def initialize(id:, state:, url:, message:, files: [], client:, **)
      @id = id
      @state = state
      @message = message
      @url = url
      @client = client
      @files = instantiate_files(files)
      # Should this be frozen?
      freeze
    end

    def prepare_file_upload(file:, part_number:)
      url = file.request_transfer_upload_url(transfer_id: @id, part_number: part_number)
      chunk_size = file.multipart.chunk_size
      [url, chunk_size]
    end

    def prepare_file_completion(file:)
      file.complete_transfer_file(transfer_id: @id)
    end

    def instantiate_files(files)
      files.map do |file|
        WeTransfer::RemoteFile.new(file.merge(transfer: self))
      end
    end
  end
end
