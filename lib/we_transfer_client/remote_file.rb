class RemoteFile
  attr_reader :multipart, :name, :type, :id, :url

  def initialize(id:, name:, size:, url: nil, type: 'file', multipart:)
    @id = id
    @name = name
    @size = size
    @url = url
    @type = type
    @size = size
    multi = Struct.new(*multipart.keys)
    @multipart = multi.new(*multipart.values)
  end
end
