require 'faraday'
require 'logger'
require 'ks'
require 'securerandom'
require 'json'
require 'open-uri'
require 'open_uri_redirections'

class WeTransferClient
  require_relative 'we_transfer_client/version'
  require_relative 'we_transfer_client/future_file_item'
  require_relative 'we_transfer_client/future_web_item'
  require_relative 'we_transfer_client/future_transfer'
  require_relative 'we_transfer_client/transfer_builder'
  require_relative 'we_transfer_client/remote_transfer'
  require_relative 'we_transfer_client/remote_item'

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

  def create_transfer(name:, description:)
    builder = TransferBuilder.new
    yield(builder)
    future_transfer = FutureTransfer.new(name: name, description: description, items: builder.items)
    create_and_upload(future_transfer)
  end

  def create_empty_transfer(name:, description:)
    future_transfer = FutureTransfer.new(name: name, description: description, items: [])
    create_and_upload(future_transfer)
  end

  def create_and_upload(xfer)
    authorize_if_no_bearer_token!
    response = faraday.post(
      '/v1/transfers',
      JSON.pretty_generate(xfer.to_create_transfer_params),
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    create_transfer_response = JSON.parse(response.body, symbolize_names: true)

    remote_transfer = hash_to_struct(create_transfer_response, RemoteTransfer)
    remote_transfer.items = remote_transfer.items.map do |remote_item_hash|
      hash_to_struct(remote_item_hash, RemoteItem)
    end

    item_id_map = Hash[xfer.items.map(&:local_identifier).zip(xfer.items)]

    create_transfer_response.fetch(:items).each do |remote_item|
      local_item = item_id_map.fetch(remote_item.fetch(:local_identifier))
      next unless local_item.is_a?(FutureFileItem)
      remote_item_id = remote_item.fetch(:id)

      put_io_in_parts(
        remote_item_id,
        remote_item.fetch(:meta).fetch(:multipart_parts),
        remote_item.fetch(:meta).fetch(:multipart_upload_id),
        local_item.io
      )

      complete_response = faraday.post(
        "/v1/files/#{remote_item_id}/uploads/complete",
        '{}',
        auth_headers.merge('Content-Type' => 'application/json')
      )
      ensure_ok_status!(complete_response)
    end
    remote_transfer
  end

  def hash_to_struct(hash, struct_class)
    members = struct_class.members
    struct_attrs = Hash[members.zip(hash.values_at(*members))]
    struct_class.new(**struct_attrs)
  end

  def put_io_in_parts(item_id, n_parts, multipart_id, io)
    chunk_size = MAGIC_PART_SIZE
    (1..n_parts).each do |part_n_one_based|
      response = faraday.get("/v1/files/#{item_id}/uploads/#{part_n_one_based}/#{multipart_id}", {}, auth_headers)
      ensure_ok_status!(response)
      response = JSON.parse(response.body, symbolize_names: true)

      upload_url = response.fetch(:upload_url)
      part_io = StringIO.new(io.read(chunk_size)) # needs a lens
      part_io.rewind
      response = faraday.put(upload_url, part_io, 'Content-Type' => 'binary/octet-stream', 'Content-Length' => part_io.size.to_s)
      ensure_ok_status!(response)
    end
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
    response = faraday.post('/v1/authorize', '{}', 'Content-Type' => 'application/json', 'X-API-Key' => @api_key)
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
