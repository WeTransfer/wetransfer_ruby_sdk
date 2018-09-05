class RemoteLink < Dry::Struct::Value
  attr_accessor :id, :url, :meta, :title, :type

  def initialize
    # super(meta: Struct.new())
  end
end
