module WeTransfer
  class RemoteFile
    TRANSFER_XOR_BOARD_PRESENT_ERROR =
      "#{name} should be initialized with either a :board or a :transfer kw param".freeze

    attr_reader :multipart, :name, :id, :url, :type, :size

    def initialize(id:, name:, url: nil, multipart:, transfer: nil, board: nil, size:, **)
      raise WeTransfer::Client::Error, TRANSFER_XOR_BOARD_PRESENT_ERROR unless transfer.nil? ^ board.nil?

      @transfer = transfer
      @id = id
      @name = name
      @size = size
      @url = url
      @type = "file"
      @multipart = Struct.new(*multipart.keys).new(*multipart.values)
    end

    def request_transfer_upload_url(transfer_id:, part_number:)
      response = @transfer.request_as.get(
        "/v2/transfers/#{transfer_id}/files/#{id}/upload-url/#{part_number}",
        {},
        # @transfer.auth_headers
      )
      @transfer.ensure_ok_status!(response)
      JSON.parse(response.body).fetch("url")
    end

    def request_board_upload_url(board_id:, part_number:)
      response = @client.request_as.get(
        "/v2/boards/#{board_id}/files/#{@id}/upload-url/#{part_number}/#{@multipart.id}",
        {},
        # @client.auth_headers
      )
      @client.ensure_ok_status!(response)
      JSON.parse(response.body, symbolize_names: true).fetch(:url)
    end

    def complete_transfer_file(transfer_id:)
      body = { part_numbers: @multipart.part_numbers }
      response = @transfer.request_as.put(
        "/v2/transfers/#{transfer_id}/files/#{@id}/upload-complete",
        body.to_json
        # @transfer.auth_headers
      )
      @transfer.ensure_ok_status!(response)
      JSON.parse(response.body, symbolize_names: true)
    end

    def complete_board_file(board_id:)
      response = @client.request_as.put(
        "/v2/boards/#{board_id}/files/#{@id}/upload-complete",
        '{}',
        # @client.auth_headers
      )
      @client.ensure_ok_status!(response)
      JSON.parse(response.body, symbolize_names: true)
    end
  end
end
