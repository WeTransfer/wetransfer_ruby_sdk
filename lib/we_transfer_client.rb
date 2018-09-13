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

  def create_transfer(message:)
    builder = TransferBuilder.new
    yield(builder)
    future_transfer = FutureTransfer.new(message: message, files: builder.items)
    create_remote_transfer(future_transfer)
  end

  def create_board(name:, description:)
    builder = BoardBuilder.new
    yield(builder) if block_given?
    future_board = FutureBoard.new(name: name, description: description, items: builder.items)
    create_remote_board(future_board)
  end

  def add_items(board:)
    builder = BoardBuilder.new
    yield(builder)
    add_items_to_remote_board(builder.items, board)
  rescue LocalJumpError
    raise ArgumentError, 'No items where added to the board'
  end

  def upload_file(object:, file:, io:)
    put_io_in_parts(object, file, io)
  end

  def complete_transfer(transfer:)
    complete_transfer_call(transfer)
  end

  def get_board(board_id:)
    request_board(board_id)
  end

  def get_transfer(transfer_id:)
    request_transfer(transfer_id)
  end

  def complete_file!(object:, file:)
    response = object.is_a?(RemoteTransfer) ? complete_transfer_file(object, file) : complete_board_file(object, file)
    ensure_ok_status!(response)
    JSON.parse(response.body, symbolize_names: true)
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
    RemoteTransfer.new(JSON.parse(response.body, symbolize_names: true))
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

  def put_io_in_parts(object, file, io)
    (1..file.multipart.part_numbers).each do |part_n_one_based|
      if object.is_a?(RemoteTransfer)
        upload_url = request_transfer_upload_url(transfer_id: object.id, file: file, part_number: part_n_one_based).fetch(:url)
        chunk_size = file.multipart.chunk_size
      else
        upload_url = request_board_upload_url(board_id: object.id, file: file, part_number: part_n_one_based).fetch(:url)
        chunk_size = MAGIC_PART_SIZE
      end
      part_io = StringIO.new(io.read(chunk_size))
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

  def request_board_upload_url(board_id:, file:, part_number:)
    response = faraday.get(
      "/v2/boards/#{board_id}/files/#{file.id}/upload-url/#{part_number}/#{file.multipart.id}",
      {},
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def request_transfer_upload_url(transfer_id:, file:, part_number:)
    response = faraday.get(
      "/v2/transfers/#{transfer_id}/files/#{file.id}/upload-url/#{part_number}",
      {},
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def complete_transfer_file(object, file)
    body = {part_numbers: file.multipart.part_numbers}
    faraday.put(
      "/v2/transfers/#{object.id}/files/#{file.id}/upload-complete",
      JSON.pretty_generate(body),
      auth_headers.merge('Content-Type' => 'application/json')
    )
  end

  def complete_board_file(object, file)
    faraday.put(
      "/v2/boards/#{object.id}/files/#{file.id}/upload-complete",
      '{}',
      auth_headers.merge('Content-Type' => 'application/json')
    )
  end

  def complete_transfer_call(object)
    authorize_if_no_bearer_token!
    response = faraday.put(
      "/v2/transfers/#{object.id}/finalize",
      '',
      auth_headers.merge('Content-Type' => 'application/json')
    )
    # binding.pry
    ensure_ok_status!(response)
    RemoteTransfer.new(JSON.parse(response.body, symbolize_names: true))
  end

  def request_board(board_id)
    authorize_if_no_bearer_token!
    response = faraday.get(
      "/v2/boards/#{board_id}",
      {},
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    RemoteBoard.new(JSON.parse(response.body, symbolize_names: true))
  end

  def request_transfer(transfer_id)
    authorize_if_no_bearer_token!
    response = faraday.get(
      "/v2/transfers/#{transfer_id}",
      {},
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    RemoteTransfer.new(JSON.parse(response.body, symbolize_names: true))
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
