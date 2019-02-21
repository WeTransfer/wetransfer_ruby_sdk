# frozen_string_literal: true

require 'faraday'
require 'logger'
require 'json'

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
require_relative 'we_transfer_client/transfers'
require_relative 'we_transfer_client/boards'

%w[communication_helper transfer mini_io we_transfer_file ].each do |file|
  require_relative "we_transfer/#{file}"
end

module WeTransfer
  class Client
    include CommunicationHelper

    class Error < StandardError; end
    NullLogger = Logger.new(nil)

    API_URL_BASE = 'https://dev.wetransfer.com'

    # include WeTransfer::Client::Transfers
    # include WeTransfer::Client::Boards

    ## initialize a WeTransfer::Client
    #
    # @param api_key [String] The API key you want to authenticate with
    # @param logger [Logger] (NullLogger) your custom logger
    #
    # @return [WeTransfer::Client]
    def initialize(api_key:, logger: NullLogger)
      CommunicationHelper.api_key = api_key
      @bearer_token = nil
      @logger = logger
      CommunicationHelper.logger = logger
    end

    def create_transfer(**args, &block)
      transfer = WeTransfer::Transfer.new(args, &block)
      @transfer = transfer

      # TODO: Either we have an accessor for transfer, or we're not returning self - the transfer is unavailable otherwise
      self
    end

    # def upload_file(object:, file:, io:)
    #   put_io_in_parts(object: object, file: file, io: io)
    # end

    # def complete_file!(object:, file:)
    #   object.prepare_file_completion(client: self, file: file)
    # end

    # def check_for_file_duplicates(files, new_file)
    #   if files.select { |file| file.name == new_file.name }.size != 1
    #     raise ArgumentError, 'Duplicate file entry'
    #   end
    # end

    # def put_io_in_parts(object:, file:, io:)
    #   (1..file.multipart.part_numbers).each do |part_n_one_based|
    #     upload_url, chunk_size = object.prepare_file_upload(client: self, file: file, part_number: part_n_one_based)
    #     part_io = StringIO.new(io.read(chunk_size))
    #     part_io.rewind
    #     response = request_as.put(
    #       upload_url,
    #       part_io,
    #       'Content-Type' => 'binary/octet-stream',
    #       'Content-Length' => part_io.size.to_s
    #     )
    #     ensure_ok_status!(response)
    #   end
    #   {success: true, message: 'File Uploaded'}
    # end
  end
end
