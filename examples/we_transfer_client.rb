require 'faraday'
require 'logger'
require 'ks'

class WeTransferClient
  NULL_LOGGER = Logger.new(nil)

  class FutureFileItem < Ks.strict(:name, :io)
    def initialize(*kwargs)
      @uuid = SecureRandom.uuuid
    end

    def to_item_request_params
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

  class RemoteTransfer
    attr_accessor :items

    def to_create_transfer_params
      {
        name: name,
        description: description,
        items: Array(@items).map(&:to_item_request_params),
      }
    end

    def short_url
      'xxx'
    end
  end

  def initialize(api_key:, logger: NULL_LOGGER)
    @api_key = api_key.to_str
    @logger = logger
  end
  
  def create_transfer(title:, message:)
    builder = TransferBuilder.new
    yield(builder)
    xfer = RemoteTransfer.new
    xfer
  end

  def auth_headers
    raise 'No bearer token retrieved yet' unless @bearer_token
    {
      'X-API-Key' => @api_key,
      'Authorization' => ('Bearer %s' % @bearer_token),
    }
  end
end
