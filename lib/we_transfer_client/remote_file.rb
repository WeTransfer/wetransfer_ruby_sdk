class RemoteFile
  attr_accessor :id, :name, :size, :url, :type, :multipart

  def initialize(**kwargs)
    @id ||= kwargs[:id]
    @name ||= kwargs[:name]
    @size ||= kwargs[:size]
    @url ||= kwargs[:url]
    @type ||= kwargs[:type]
    @size ||= kwargs[:size]
    multi ||= Struct.new(*kwargs[:multipart].keys)
    @multipart = multi.new(*kwargs[:multipart].values)
  end
end
