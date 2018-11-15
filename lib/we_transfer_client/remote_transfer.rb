module WeTransfer
  class RemoteTransfer
    attr_reader :files, :url, :state, :id

    def initialize(id:, state:, url:, message:, files: [], client:)
      @id = id
      @state = state
      @message = message
      @url = url
      @files = files_to_class(files)
    end

    def prepare_file_upload(client:, file:, part_number:)
      url = file.request_transfer_upload_url(transfer_id: @id, part_number: part_number)
      chunk_size = file.multipart.chunk_size
      [url, chunk_size]
    end

    def prepare_file_completion(client:, file:)
      file.complete_transfer_file(transfer_id: @id)
    end

    def files_to_class(files)
      files.map { |x| WeTransfer::RemoteFile.new(x) }
    end
  end
end
