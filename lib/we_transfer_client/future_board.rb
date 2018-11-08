module WeTransfer
  class FutureBoard
    attr_reader :name, :description, :items

    def initialize(name:, description: nil, items: [])
      @name = name
      @description = description
      @items = items
    end

    def files
      binding.pry
      @items.select { |item| item.is_a?(WeTransfer::FutureFile) }
    end

    def links
      @items.select { |item| item.is_a?(WeTransfer::FutureLink) }
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
end