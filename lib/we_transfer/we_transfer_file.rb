module WeTransfer
  class WeTransferFile

    attr_reader :name

    def initialize(name: nil, size: nil, io: nil)
      @io = io.is_a?(MiniIO) ? io : MiniIO.new(io)
      @name = name || @io.name
      @size = size || @io.size

      raise ArgumentError, "Need a file name and a size, or io should provide it" unless @name && @size
    end

    def as_json_request_params
      {
        name: @name,
        size: @size,
      }
    end

    # def persist()
  end
end
