require 'faraday'
require 'logger'
require 'ks'
require 'securerandom'
require 'json'

class WeTransferClient
  require_relative 'we_transfer_client/version'

  class Error < StandardError
  end

  NULL_LOGGER = Logger.new(nil)
  MAGIC_PART_SIZE = 6 * 1024 * 1024
  EXPOSED_COLLECTION_ATTRIBUTES = [:id, :version_identifier, :state, :shortened_url, :name, :description, :size, :items]
  EXPOSED_ITEM_ATTRIBUTES = [:id, :local_identifier, :content_identifier, :name, :size, :mime_type]

  class FutureFileItem < Ks.strict(:name, :io, :local_identifier)
    def initialize(**kwargs)
      super(local_identifier: SecureRandom.uuid, **kwargs)
    end

    def to_item_request_params
      # Ideally the content identifier should stay the same throughout multiple
      # calls if the file contents doesn't change.
      {
        content_identifier: 'file',
        local_identifier: local_identifier,
        filename: name,
        filesize: io.size,
      }
    end
  end

  class TransferBuilder
    attr_reader :items

    def initialize
      @items = []
    end

    def add_file(name:, io:)
      ensure_io_compliant!(io)
      @items << FutureFileItem.new(name: name, io: io)
      true
    end

    def add_file_at(path:)
      add_file(name: File.basename(path), io: File.open(path, 'rb'))
    end

    def ensure_io_compliant!(io)
      io.seek(0)
      io.read(1) # Will cause things like Errno::EACCESS to happen early, before the upload begins
      io.seek(0) # Also rewinds the IO for later uploading action
      size = io.size # Will cause a NoMethodError
      raise Error, 'The IO object given to add_file has a size of 0' if size <= 0
    rescue NoMethodError
      raise Error, "The IO object given to add_file must respond to seek(), read() and size(), but #{io.inspect} did not"
    end
  end

  class FutureTransfer < Ks.strict(:name, :description, :items)
    def to_create_transfer_params
      {
        name: name,
        description: description,
        items: items.map(&:to_item_request_params),
      }
    end
  end

  class RemoteTransfer < Ks.strict(*EXPOSED_COLLECTION_ATTRIBUTES)
  end

  class RemoteItem < Ks.strict(*EXPOSED_ITEM_ATTRIBUTES)
  end

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
