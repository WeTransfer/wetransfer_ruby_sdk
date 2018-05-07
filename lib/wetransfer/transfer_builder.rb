module WeTransfer
  class TransferBuilder
    def initialize(transfer: nil)
      @transfer = if transfer.nil?
                    Transfer.new
                  else
                    transfer
                  end
    end

    def name_description(name: nil, description: nil)
      @transfer.name = name || "File Transfer: #{Time.now.strftime('%d-%m-%Y')}"
      @transfer.description = description || 'Transfer generated with WeTransfer Ruby SDK'
    end

    def self.id(transfer:, id:)
      transfer.id = id
    end

    def self.shortened_url(transfer:, url:)
      transfer.shortened_url = url
    end

    def transfer
      @transfer
    end
  end
end
