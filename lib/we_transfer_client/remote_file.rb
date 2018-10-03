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
