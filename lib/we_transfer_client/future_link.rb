class FutureLink
  attr_reader :url, :title

  def initialize(url:, title: url)
    @url = url
    @title = title
  end

  def as_json_request_params
    {
      url: url,
      title: title,
    }
  end

  def add_to_board(client:, remote_board:)
    client.authorize_if_no_bearer_token!
    response = client.request_as.post(
      "/v2/boards/#{remote_board.id}/links",
      # this needs to be a array with hashes => [{name, filesize}]
      JSON.generate([as_json_request_params]),
      client.auth_headers.merge('Content-Type' => 'application/json')
    )
    client.ensure_ok_status!(response)
    file_item = JSON.parse(response.body, symbolize_names: true).first
    remote_board.items << RemoteLink.new(file_item)
  end
end
