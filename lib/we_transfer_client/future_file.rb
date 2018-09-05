class FutureFile
  attr_reader :name, :io
  def initialize(name:, io:)
    raise ArgumentError, 'io keyword should be an IO instance' unless io.is_a?(::IO)

    @name = name
    @io = io
  end

  def to_request_params
    {
      name: @name,
      size: @io.size,
    }
  end
end
