class RemoteLink
  attr_reader :type
  def initialize(id:, url:, meta:, type:)
    @id = id
    @url = url
    @meta = meta
    @type = type
  end
end
