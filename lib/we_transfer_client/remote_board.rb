class RemoteBoard
  attr_reader :id, :items, :url, :state

  def initialize(id:, state:, url:, name:, description: nil, items: [])
    @id = id
    @state = state
    @url = url
    @name = name
    @description = description
    @items = item_to_class(items)
  end

  def item_to_class(items)
    items.map{|x| x[:type] == 'file' ?  RemoteFile.new(x) : RemoteLink.new(x)}
  end
end
