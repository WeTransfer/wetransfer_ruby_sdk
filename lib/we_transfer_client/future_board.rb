class FutureBoard
  attr_reader :name, :description, :items

  def initialize(name:, description: nil, items: [])
    @name = name
    @description = description
    @items = items
  end

  def file_items
    @items.select { |item| item.class == FutureFile }
  end

  def link_items
    @items.select { |item| item.class == FutureLink }
  end

  def to_initial_request_params
    {
      name: name,
      description: description,
    }
  end

  def to_request_params
    {
      name: name,
      description: description,
      items: items.map(&:to_request_params),
    }
  end
end
