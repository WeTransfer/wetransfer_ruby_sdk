module WeTransfer
  class FutureLink
    attr_reader :url, :title

    def initialize(url:, title: url, client:)
      @client = client
      @url = url.to_str
      @title = title.to_str
      @state = PENDING
    end

    COMPLETED = 'completed'
    PENDING = 'pending'

    def to_request_params
      {
        url: url,
        title: title,
      }
    end

    def add_to_board(remote_board:)
      return if @state == COMPLETED
      @parent_object = remote_board
      check_for_duplicates
      @client.authorize_if_no_bearer_token!
      response = @client.faraday.post(
        "/v2/boards/#{remote_board.id}/links",
        JSON.pretty_generate([to_request_params]),
        @client.auth_headers.merge('Content-Type' => 'application/json')
      )
      @client.ensure_ok_status!(response)
      file_item = JSON.parse(response.body, symbolize_names: true).first
      @remote_link = WeTransfer::RemoteLink.new(file_item)
      @parent_object.items << @remote_link
      @state = COMPLETED
      @remote_link
    end

    private

    def check_for_duplicates
      if @parent_object.links.select { |link| link.url == @url }.size >= 1
        raise WeTransfer::TransferIOError, 'Duplicate link entry'
      end
    end
  end
end
