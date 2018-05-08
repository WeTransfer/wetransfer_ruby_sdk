require 'faraday'
require 'logger'
require 'ks'
require 'securerandom'

class WeTransferClient
  NULL_LOGGER = Logger.new(nil)

  class FutureFileItem < Ks.strict(:name, :io)
    def initialize(*kwargs)
      super
      @uuid = SecureRandom.uuid
    end

    def to_item_request_params
      # Ideally the content identifier should stay the same throughout multiple
      # calls if the file contents doesn't change.
      {
        content_identifier: 'file',
        local_identifier: @uuid,
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

  class RemoteTransfer < Ks.strict(:name, :description, :items)
    def to_create_transfer_params
      {
        name: name,
        description: description,
        items: items.map(&:to_item_request_params),
      }
    end

    def short_url
      'xxx'
    end
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
    xfer = RemoteTransfer.new(name: title, description: message, items: Array(builder.items))
    $stderr.puts xfer.inspect
    create_and_upload(xfer)
    xfer
  end

  def create_and_upload(xfer)
    authorize_if_no_bearer_token!
    $stderr.puts xfer.to_create_transfer_params
  end

  def authorize_if_no_bearer_token!
    return if @bearer_token
    faraday = Faraday.new(@api_url_base)
    response = faraday.post("/v1/authorize", {}, {'X-API-Key' => @api_key})
    @bearer_token = JSON.parse(response.body).fetch('token')
  end

  def auth_headers
    raise 'No bearer token retrieved yet' unless @bearer_token
    {
      'X-API-Key' => @api_key,
      'Authorization' => ('Bearer %s' % @bearer_token),
    }
  end
end
