module WeTransfer
  # TODO: DRY up regarding FutureFile
  class FutureLink
    attr_reader :url, :title

    ADDED = 'added'.freeze
    INITIALIZED = 'initialized'.freeze

    def initialize(url:, title: url, client:)
      @url = url.to_str
      @title = title.to_str
      @client = client
      @state = INITIALIZED
    end

    def to_request_params
      {
        url: url,
        title: title,
      }
    end

    def add_to_board(remote_board:)
      return if @state == ADDED
      @parent_object = remote_board
      check_for_duplicates
      response = @client.request_as.post(
        "/v2/boards/#{remote_board.id}/links",
        JSON.pretty_generate([to_request_params]),
        @client.auth_headers # .merge('Content-Type' => 'application/json')
      )
      @client.ensure_ok_status!(response)
      file_item = JSON.parse(response.body, symbolize_names: true).first
      @remote_link = WeTransfer::RemoteLink.new(file_item)

      @parent_object.items << @remote_link
      @state = ADDED

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
