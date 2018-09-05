class FutureTransfer
  attr_accessor :name, :description, :items

  def to_create_transfer_params
    {
      name: name,
      description: description,
      items: items.map(&:to_item_request_params),
    }
  end
end
