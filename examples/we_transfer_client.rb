require 'faraday'
require 'logger'
require 'ks'
require 'securerandom'
require 'json'

class WeTransferClient
  NULL_LOGGER = Logger.new(nil)

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
      # File access checks etc. can go here
      unless io.respond_to?(:read) && io.respond_to?(:seek) && io.respond_to?(:size)
        raise ArgumentError, "The IO object given to add_file must respond to seek(), read() and size() at the minimum"
      end
      @items << FutureFileItem.new(name: name, io: io)
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

  class RemoteTransfer < Ks.strict(:id, :version_identifier, :state, :shortened_url, :name, :description, :size, :items)
  end

  class RemoteItem < Ks.strict(:id, :local_identifier, :content_identifier, :name, :size, :mime_type)
  end

  def initialize(api_key:, logger: NULL_LOGGER)
    @api_url_base = 'https://dev.wetransfer.com'
    @api_key = api_key.to_str
    @bearer_token = nil
    @logger = logger
  end
  
  def create_transfer(title:, message:)
    builder = TransferBuilder.new
    yield(builder)
    future_transfer = FutureTransfer.new(name: title, description: message, items: Array(builder.items))
    remote_transfer =create_and_upload(future_transfer)
    remote_transfer
  end

  def create_and_upload(xfer)
    authorize_if_no_bearer_token!
    response = faraday.post(
      "/v1/transfers",
      JSON.pretty_generate(xfer.to_create_transfer_params),
      auth_headers.merge('Content-Type' => 'application/json')
    )
    ensure_ok_status!(response)
    create_transfer_response = JSON.parse(response.body, symbolize_names: true)
    item_id_map = Hash[xfer.items.map(&:local_identifier).zip(xfer.items)]

    create_transfer_response.fetch(:items).each do |remote_item|
      local_item = item_id_map.fetch(remote_item.fetch(:local_identifier))
      upload_url = remote_item.fetch(:upload_url)

      put_response = put_io(upload_url, local_item.io)
      ensure_ok_status!(put_response)

      remote_id = remote_item.fetch(:id)
      complete_response = faraday.post(
        "/v1/files/#{remote_id}/uploads/complete",
        '{}',
        auth_headers.merge('Content-Type' => 'application/json')
      )
      ensure_ok_status!(complete_response)
    end
    remote_transfer_attrs = hash_to_struct(create_transfer_response, RemoteTransfer)
    remote_transfer_attrs[:items] = remote_transfer_attrs[:items].map do |remote_item_hash|
      hash_to_struct(remote_item_hash, RemoteItem)
    end
    RemoteTransfer.new(**remote_transfer_attrs)
  end

  def hash_to_struct(hash, struct_class)
    Hash[struct_class.members.zip(hash.values_at(*struct_class.members))]
  end

  def put_io(to_url, io)
    io.seek(0)
    faraday.put(to_url, io, {'Content-Type' => 'binary/octet-stream', 'Content-Length' => io.size.to_s})
  end

  def faraday
    Faraday.new(@api_url_base) do |c|
      c.response :logger, @logger
      c.adapter Faraday.default_adapter
    end
  end
  
  def authorize_if_no_bearer_token!
    return if @bearer_token
    response = faraday.post("/v1/authorize", '{}', {'Content-Type'=> 'application/json', 'X-API-Key' => @api_key})
    ensure_ok_status!(response)
    @bearer_token = JSON.parse(response.body).fetch('token')
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
      return
    when 400..499
      raise "Response had a #{response.status} code, the server will not accept this request even if retried"
    when 500..504
      raise "Response had a #{response.status} code, we should retry"
    else
      raise "Response had a #{response.status} code, no idea what to do with that"
    end
  end
end
