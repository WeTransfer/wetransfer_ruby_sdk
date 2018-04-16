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
      @transfer = WeTransfer::Transfers.new(@client).create_transfer(name: @options[:name],
                                                                        description: @options[:description],
                                                                        items: items_array)

      @transfer = WeTransfer::Transfers.new(@client).get_upload_urls(transfer: @transfer)

      handle_items
      puts @transfer.shortened_url
    rescue => e
      Hash[success: false, message: e.message]
    end


    private

    def handle_items
      @files.each do |file|
        item_object = @transfer.items.select{|t| t['name'] == file.split('/').last}.first
        file_object = File.open(file)
        if item_object['meta']['multipart_parts'] > 1
          WeTransfer::Transfers.new(@client).multi_part_file(item: item_object ,file: file_object)
        else
          WeTransfer::Transfers.new(@client).single_part_file(item: item_object ,file: file_object)
        end
        WeTransfer::Transfers.new(@client).complete_file(item: item_object)
      end
    end
  end
end
