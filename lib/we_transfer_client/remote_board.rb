class RemoteBoard

  def initialize(id:, state:, url:, name:, description: nil, items: [])
    @id = id
    @state = state
    @url = url
    @name = name
    @description = description
    @items = items
  end
end
