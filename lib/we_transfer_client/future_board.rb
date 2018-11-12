module WeTransfer
  class FutureBoard
    attr_reader :name, :description

    def initialize(name:, description: nil)
      @name = name
      @description = description
    end

    def to_initial_request_params
      {
        name: name,
        description: description,
      }
    end
  end
end