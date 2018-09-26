class FutureFile
  attr_reader :name, :io

  def initialize(name:, io:)
    raise ArgumentError, 'io keyword should be an IO instance' unless io.is_a?(::IO)
    @name = name
    @io = io
  end

  def to_request_params
    {
      name: @name,
      size: @io.size.to_i,
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
    remote_board.items << RemoteFile.new(file_item)
  end
end
