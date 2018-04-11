module WeTransfer
  class Transfer
    attr_accessor :id, :name, :description, :shortened_url, :items

    def initialize(id:, name:, description: nil, shortened_url:, items: nil)
      @id = id
      @name = name
      @description = description
      @shortened_url = shortened_url
      @items = items || []
    end
  end
end
