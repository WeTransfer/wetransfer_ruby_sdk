class RemoteBoard
  attr_accessor :id, :state, :url, :name, :description, :items

  def initialize(**kwargs)
    @id ||= kwargs[:id]
    @state ||= kwargs[:state]
    @url ||= kwargs[:url]
    @name ||= kwargs[:name]
    @description ||= kwargs[:description]
    @items ||= kwargs[:items]
  end
end
