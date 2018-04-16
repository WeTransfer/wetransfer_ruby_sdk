module WeTransfer
  class Upload

    def initialize(client:, files: [], options: {})
      raise ArgumentError, 'Not a WeTransfer client!' if client.class != WeTransfer::Client
      @client = client
      @files = files
      @options = options
      transfer_files
    end


    def transfer_files
      if @options.empty?
        @options[:name] = "File Transfer: #{Time.now.strftime('%d-%m-%Y')}"
        @options[:description] = 'Transfer generated with WeTransfer Ruby SDK'
      end
      items_array = []
      @files.each do |file|
        # validate on local_identifier, char max is 36
        items_array << {local_identifier: file.split('/').last,
                        content_identifier: 'file',
                        filename: file.split('/').last,
                        filesize: File.open(file).size
                        }
      end
      @transfer = WeTransfer::Transfers.new(@client).create_new_transfer(name: @options[:name],
                                                                        description: @options[:description],
                                                                        items: items_array)

      @transfer = WeTransfer::Transfers.new(@client).mp_upload_urls(transfer: @transfer)
      upload_items
      puts @transfer.shortened_url
      return @transfer
    rescue => e
      binding.pry
      puts e.message
    end


    private

    def upload_items
      # @transfer.items
      # get all the files from @files and upload them to the provided s3 URL
      @files.each do |file|
        transfer_object = @transfer.items.select{|t| t['name'] == file.split('/').last}.first
        file_object = File.open(file)
        if transfer_object['meta']['multipart_parts'] > 1
          #do a multipart upload
          transfer_object['upload_url'].each do |url|
            # optimal chunksize is 6mb
            chunk = file_object.read(6_291_456)
            conn = Faraday.new(url: url) do |faraday|
              faraday.request :multipart
              faraday.response :logger
              faraday.adapter :net_http
            end
            response = conn.put do |req|
              req.headers['Content-Length'] = chunk.size.to_s
              req.body = chunk
            end
          end
        else
          #single part
          conn = Faraday.new(url: transfer_object['upload_url']) do |faraday|
            faraday.request :multipart
            faraday.response :logger
            faraday.adapter :net_http
          end
          response = conn.put do |req|
            req.headers['Content-Length'] = file_object.size.to_s
            req.body = file_object
          end
        end
        WeTransfer::Transfers.new(@client).complete_file(file: transfer_object)
      end
    # rescue => e
    #   binding.pry
    end
  end
end
