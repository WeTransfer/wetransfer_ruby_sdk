module WeTransfer
  class TransferIOError < StandardError; end
  class FutureFile

    attr_reader :name, :size

    def initialize(name:, size:)
      @name = name
      @size = size
    end

    def to_request_params
      {
        name: @name,
        size: @size,
      }
    end

    def add_to_board(client:, remote_board:)
      client.authorize_if_no_bearer_token!
      response = client.faraday.post(
        "/v2/boards/#{remote_board.id}/files",
        # this needs to be a array with hashes => [{name, filesize}]
        JSON.pretty_generate([to_request_params]),
        client.auth_headers.merge('Content-Type' => 'application/json')
      )
      client.ensure_ok_status!(response)
      file_item = JSON.parse(response.body, symbolize_names: true).first
      remote_file =  WeTransfer::RemoteFile.new(file_item)
      remote_board.items << remote_file
      remote_file
    end

    def upload_file(client:, remote_object:, remote_file:, io:)
      ensure_io_compliant!(io: io)
      ensure_right_file!(remote_file, io)
      put_io_in_parts(client: client, remote_object: remote_object, remote_file: remote_file, io: io)
    end

    def complete_file(client:, remote_object:, remote_file:)
      remote_object.prepare_file_completion(client: client, file: remote_file)
    end

    def check_for_duplicates(file_list)
      if file_list.select { |file| file.name == name }.size != 1
        raise ArgumentError, 'Duplicate file entry'
      end
    end

    private

    def put_io_in_parts(client:, remote_object:, remote_file:, io:)
      (1..remote_file.multipart.part_numbers).each do |part_n_one_based|
        upload_url, chunk_size = remote_object.prepare_file_upload(client: client, file: remote_file, part_number: part_n_one_based)
        part_io = StringIO.new(io.read(chunk_size))
        part_io.rewind
        response = client.faraday.put(
          upload_url,
          part_io,
          'Content-Type': 'binary/octet-stream',
          'Content-Length': part_io.size.to_s
        )
        client.ensure_ok_status!(response)
      end
    end

    def ensure_right_file!(remote_file, io)
      if io.size != remote_file.size
        raise TransferIOError, "#{File.basename(io)}, is a different size then #{remote_file.name}"
      end
    end

    def ensure_io_compliant!(io:)
      io.seek(0)
      io.read(1) # Will cause things like Errno::EACCESS to happen early, before the upload begins
      io.seek(0) # Also rewinds the IO for later uploading action
      size = io.size # Will cause a NoMethodError
      raise TransferIOError, "#{File.basename(io)}, given to add_file has a size of 0" if size <= 0
    rescue NoMethodError
      raise TransferIOError, "#{File.basename(io)}, given to add_file must respond to seek(), read() and size(), but #{io.inspect} did not"
    end
  end
end