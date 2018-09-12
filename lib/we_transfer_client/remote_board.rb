class RemoteBoard
  ItemTypeError = Class.new(NameError)

  attr_reader :id, :items, :url, :state

  def initialize(id:, state:, url:, name:, description: '', items: [])
    @id = id
    @state = state
    @url = url
    @name = name
    @description = description
    @items = to_instances(items)
  end

  private

  def to_instances(items)
    items.map do |item|
      begin
        remote_class = "Remote#{item[:type].capitalize}"
        Module.const_get(remote_class)
          .new(item)
      rescue NameError
        raise ItemTypeError, "Cannot instantiate item with type '#{item[:type]}' and id '#{item[:id]}'"
      end
    end
  end
end
