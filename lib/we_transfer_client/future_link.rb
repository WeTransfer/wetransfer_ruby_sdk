module WeTransfer
  class FutureLink
    attr_reader :url, :title

    def initialize(url:, title: url)
      @url = url
      @title = title
    end

    def to_request_params
      {
        url: url,
        title: title,
      }
    end

    def check_for_duplicates(link_list)
      if link_list.select { |link| link.url == url }.size != 1
        raise ArgumentError, 'Duplicate link entry'
      end
    end

    def add_to_board(client:, remote_board:)
      client.authorize_if_no_bearer_token!
      response = client.faraday.post(
        "/v2/boards/#{remote_board.id}/links",
        JSON.pretty_generate([to_request_params]),
        client.auth_headers.merge('Content-Type' => 'application/json')
      )
      client.ensure_ok_status!(response)
      file_item = JSON.parse(response.body, symbolize_names: true).first
      remote_board.items << WeTransfer::RemoteLink.new(file_item)
    end
  end
end