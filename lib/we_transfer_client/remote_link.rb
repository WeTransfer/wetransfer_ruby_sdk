class RemoteLink
  attr_reader :type
  def initialize(id:, url:, title:, type:)
    @id = id
    @url = url
    @title = title
    @type = type
  end
end
