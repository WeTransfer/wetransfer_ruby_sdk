module WeTransfer
  class RemoteFile
    attr_reader :multipart, :name, :id, :url, :type

    def initialize(id:, name:, size:, url: nil, type: 'file', multipart:)
      @id = id
      @name = name
      @size = size
      @url = url
      @type = type
      @size = size
      multi = Struct.new(*multipart.keys)
      @multipart = multi.new(*multipart.values)
    end

    def upload_file(object:, file:, io:)
      put_io_in_parts(object: object, file: file, io: io)
    end

    def complete_file!(object:, file:)
      object.prepare_file_completion(client: self, file: file)
    end

    def check_for_duplicates(file_list)
      if file_list.select { |file| file.name == name }.size != 1
        raise ArgumentError, 'Duplicate file entry'
      end
    end

    def request_transfer_upload_url(client:, transfer_id:, part_number:)
      response = client.faraday.get(
        "/v2/transfers/#{transfer_id}/files/#{@id}/upload-url/#{part_number}",
        {},
        client.auth_headers.merge('Content-Type' => 'application/json')
      )
      client.ensure_ok_status!(response)
      JSON.parse(response.body, symbolize_names: true).fetch(:url)
    end

    def request_board_upload_url(client:, board_id:, part_number:)
      response = client.faraday.get(
        "/v2/boards/#{board_id}/files/#{@id}/upload-url/#{part_number}/#{@multipart.id}",
        {},
        client.auth_headers.merge('Content-Type' => 'application/json')
      )
      client.ensure_ok_status!(response)
      JSON.parse(response.body, symbolize_names: true).fetch(:url)
    end

    def complete_transfer_file(client:, transfer_id:)
      body = {part_numbers: @multipart.part_numbers}
      response = client.faraday.put(
        "/v2/transfers/#{transfer_id}/files/#{@id}/upload-complete",
        JSON.pretty_generate(body),
        client.auth_headers.merge('Content-Type' => 'application/json')
      )
      client.ensure_ok_status!(response)
      JSON.parse(response.body, symbolize_names: true)
    end

    def complete_board_file(client:, board_id:)
      response = client.faraday.put(
        "/v2/boards/#{board_id}/files/#{@id}/upload-complete",
        '{}',
        client.auth_headers.merge('Content-Type' => 'application/json')
      )
      client.ensure_ok_status!(response)
      JSON.parse(response.body, symbolize_names: true)
    end
  end
end