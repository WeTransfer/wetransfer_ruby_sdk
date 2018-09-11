require 'faraday'
require 'logger'
require 'securerandom'
require 'json'

class WeTransferClient
  require_relative 'we_transfer_client/version'
  require_relative 'we_transfer_client/transfer_builder'
  require_relative 'we_transfer_client/board_builder'
  require_relative 'we_transfer_client/future_file'
  require_relative 'we_transfer_client/future_link'
  require_relative 'we_transfer_client/future_transfer'
  require_relative 'we_transfer_client/future_board'
  require_relative 'we_transfer_client/remote_transfer'
  require_relative 'we_transfer_client/remote_board'
  require_relative 'we_transfer_client/remote_link'
  require_relative 'we_transfer_client/remote_file'

  class Error < StandardError
  end

  NULL_LOGGER = Logger.new(nil)
  MAGIC_PART_SIZE = 6 * 1024 * 1024

  def initialize(api_key:, logger: NULL_LOGGER)
    @api_url_base = 'https://dev.wetransfer.com'
    @api_key = api_key.to_str
    @bearer_token = nil
    @logger = logger
  end

  def create_transfer(name:, description: )
    builder = TransferBuilder.new
    yield(builder)
    future_transfer = FutureTransfer.new(name: name, description: description, items: builder.items)
    create_and_upload(future_transfer)
  end

  def create_board(name:, description: )
    builder = BoardBuilder.new
    yield(builder) if block_given?
    future_board = FutureBoard.new(name: name, description: description, items: builder.items)
    create_remote_board(future_board)
  end

  def add_items(board: )
    builder = BoardBuilder.new
    yield(builder)
    add_items_to_remote_board(builder.items, board)
  rescue LocalJumpError
    raise ArgumentError, 'No items where added to the board'
  end

  def upload_file(board_id:, file:, io: )
    put_io_in_parts(board_id, file, io)
    complete_file!(board_id , file.id)
  end

  def get_board(board_id: )
    request_board(board_id)
  end

  private

  def create_remote_transfer(xfer)
    authorize_if_no_bearer_token!
    response = faraday.post(
      '/v2/transfers',
      JSON.pretty_generate(xfer.to_create_transfer_params),
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    create_transfer_response = JSON.parse(response.body, symbolize_names: true)
    hash_to_struct(create_transfer_response, RemoteTransfer)
  end

  def create_remote_board(board)
    authorize_if_no_bearer_token!
    response = faraday.post(
      '/v2/boards',
      JSON.pretty_generate(board.to_initial_request_params),
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    remote_board = RemoteBoard.new(JSON.parse(response.body, symbolize_names: true))
    add_items_to_remote_board(board.items, remote_board) if board.items.any?
  end

  def add_items_to_remote_board(items, board)
    items.each do |item|
      # could group every file_item and send them at the same time
      if item.is_a?(FutureFile)
        response = faraday.post(
          "/v2/boards/#{board.id}/files",
          # this needs to be a array with hashes => [{name, filesize}]
          JSON.pretty_generate([item.to_request_params]),
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        file_item = JSON.parse(response.body, symbolize_names: true).first
        board.items << RemoteFile.new(file_item)
      elsif item.is_a?(FutureLink)
        response = faraday.post(
          "/v2/boards/#{board.id}/links",
          # this needs to be a array with hashes => [{name, filesize}]
          JSON.pretty_generate([item.to_request_params]),
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        file_item = JSON.parse(response.body, symbolize_names: true).first
        board.items << RemoteLink.new(file_item)
      end
    end
    board
  end

  def put_io_in_parts(board_id, item, io)
    (1..item.multipart.part_numbers).each do |part_n_one_based|
      upload_url = request_board_upload_url(board_id: board_id, item: item, part_number: part_n_one_based).fetch(:url)
      part_io = StringIO.new(io.read(MAGIC_PART_SIZE))
      part_io.rewind
      response = faraday.put(
        upload_url,
        part_io,
        'Content-Type' => 'binary/octet-stream',
        'Content-Length' => part_io.size.to_s
      )
      ensure_ok_status!(response)
    end
  end

  def request_board_upload_url(board_id:, item:, part_number:)
    response = faraday.get(
      "/v2/boards/#{board_id}/files/#{item.id}/upload-url/#{part_number}/#{item.multipart.id}",
      {},
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def complete_file!(board_id, item_id)
    response = faraday.put(
      "/v2/boards/#{board_id}/files/#{item_id}/upload-complete",
      '{}',
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def faraday
    Faraday.new(@api_url_base) do |c|
      c.response :logger, @logger
      c.adapter Faraday.default_adapter
      c.headers = { 'User-Agent' => "WetransferRubySdk/#{WeTransferClient::VERSION} Ruby #{RUBY_VERSION}"}
    end
  end

  def authorize_if_no_bearer_token!
    return if @bearer_token
    response = faraday.post('/v2/authorize', '{}', 'Content-Type' => 'application/json', 'X-API-Key' => @api_key)
    ensure_ok_status!(response)
    @bearer_token = JSON.parse(response.body, symbolize_names: true)[:token]
    if @bearer_token.nil? || @bearer_token.empty?
      raise Error, "The authorization call returned #{response.body} and no usable :token key could be found there"
    end
  end

  def auth_headers
    raise 'No bearer token retrieved yet' unless @bearer_token
    {
      'X-API-Key' => @api_key,
      'Authorization' => ('Bearer %s' % @bearer_token),
    }
  end

  # def return_as_struct(transfer_response)
  #   if transfer_response.is_a?(Hash)
  #     transfer_response = hash_to_struct(transfer_response, RemoteBoard)
  #     if transfer_response.items.any?
  #       transfer_response.items.each do |remote_item_hash|
  #         binding.pry
  #         transfer_response.items << hash_to_struct(remote_item_hash, RemoteFile)
  #       end
  #     end
  #   end
  #   transfer_response
  # end

  def ensure_ok_status!(response)
    case response.status
    when 200..299
      nil
    when 400..499
      @logger.error { response.body }
      raise Error, "Response had a #{response.status} code, the server will not accept this request even if retried"
    when 500..504
      @logger.error { response.body }
      raise Error, "Response had a #{response.status} code, we could retry"
    else
      @logger.error { response.body }
      raise Error, "Response had a #{response.status} code, no idea what to do with that"
    end
  end
end
