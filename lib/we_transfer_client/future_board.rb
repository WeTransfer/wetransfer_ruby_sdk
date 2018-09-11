class FutureBoard
  attr_accessor :name, :description, :items

  def initialize(name:, description: nil, items: [])
    @name = name
    @description = description
    @items = items
  end

  def to_initial_request_params
    # the initial create_board endpoint doesn't accept items....
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
