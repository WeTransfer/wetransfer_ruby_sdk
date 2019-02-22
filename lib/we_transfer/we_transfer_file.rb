module WeTransfer
  class WeTransferFile
    attr_reader :name, :id, :io, :multipart, :size

    def initialize(name: nil, size: nil, io: nil)
      @io = MiniIO.new(io)
      @name = name || @io.name
      @size = size || @io.size

      raise ArgumentError, "Need a file name and a size, or io should provide it" unless @name && @size
    end

    def as_request_params
      {
        name: @name,
        size: @size,
      }
    end

    def to_h
      prepared = %i[name size id].each_with_object({}) do |prop, memo|
        memo[prop] = send(prop)
      end
      prepared[:multipart] = multipart.to_h

      prepared
    end
  end
end
