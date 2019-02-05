module WeTransfer
  # TODO: DRY up regarding FutureLink
  class FutureFile
    attr_reader :name, :size

    COMPLETED = 'completed'.freeze
    PENDING = 'pending'.freeze

    def initialize(name:, size:, transfer:)
      @transfer = transfer
      @name = name.to_s
      @size = size.to_i
      @state = PENDING
    end

    def to_request_params
      {
        name: @name,
        size: @size,
      }
    end

    def add_to_board(remote_board:)
      return if @state == COMPLETED
      @remote_board = remote_board
      ensure_no_duplicates
      response = @transfer.request_as.post(
        "/v2/boards/#{remote_board.id}/files",
        JSON.pretty_generate([to_request_params]),
        # @client.auth_headers # .merge('Content-Type' => 'application/json')
      )
      @transfer.ensure_ok_status!(response)
      file_item = JSON.parse(response.body, symbolize_names: true).first
      @remote_file ||= WeTransfer::RemoteFile.new(file_item.merge(client: @transfer.client))

      @remote_board.items << @remote_file
      @state = COMPLETED

      @remote_file
    end

    def upload_file(io:)
      ensure_io_compliant!(io)
      ensure_right_file!(io)
      put_io_in_parts(io: io)
    end

    def complete_file
      raise TransferIOError, "Cannot complete a file that isn't added anywhere" unless @remote_board

      # TODO: Could this instance var break things over many uploaded files?
      @remote_board.prepare_file_completion(file: @remote_file)
    end

    private

    def ensure_no_duplicates
      if @remote_board.files.select { |file| file.name == @name }.size >= 1
        raise TransferIOError, 'Duplicate file entry'
      end
    end

    def put_io_in_parts(io:)
      (1..@remote_file.multipart.part_numbers).each do |part_n_one_based|
        upload_url, chunk_size = @remote_board.prepare_file_upload(file: @remote_file, part_number: part_n_one_based)
        part_io = StringIO.new(io.read(chunk_size))
        part_io.rewind
        response = @transfer.request_as.put(
          upload_url,
          part_io,
          'Content-Type': 'binary/octet-stream',
          'Content-Length': part_io.size.to_s
        )
        @transfer.ensure_ok_status!(response)
      end
      @remote_file
    end

    def select_file_on_name(name:)
      @remote_file ||= files.select { |file| file.name == name }.first
      return @remote_file if @remote_file
      raise WeTransfer::TransferIOError, "File with name '#{name}' is not found"
    end

    def ensure_right_file!(io)
      if io.size != @remote_file.size
        raise TransferIOError, "#{File.basename(io)}, is a different size then #{@remote_file.name}"
      end
    end

    def ensure_io_compliant!(io)
      io.seek(0)
      io.read(1) # Could raise  Errno::EACCESS and IOError
      io.seek(0)
      size = io.size # Could cause a NoMethodError
      raise TransferIOError, "#{File.basename(io)}, given to add_file has a size of 0" if size <= 0
    rescue NoMethodError, IOError
      raise TransferIOError, "#{File.basename(io)}, given to add_file must respond to seek(), read() and size(), but #{io.inspect} did not"
    end
  end
end
