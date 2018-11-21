module WeTransfer
  class RemoteLink
    attr_reader :type, :url

    def initialize(id:, url:, type:, meta:)
      @id = id
      @url = url
      @title = meta.fetch(:title)
      @type = type
    end
  end
end
