class RemoteTransfer
  def initializer(id:, version_identifier:, state:, shortened_url:, name:, description: nil, size:, items: [])
    @id = id
    @version_identifier = version_identifier
    @state = state
    @shortened_url = shortened_url
    @name = name
    @description = description
    @size = size
    @items = items
  end
end
