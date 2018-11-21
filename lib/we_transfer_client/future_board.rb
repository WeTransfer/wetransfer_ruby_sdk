module WeTransfer
  class FutureBoard
    attr_reader :name, :description

    def initialize(name:, description: '')
      @name = name.to_s
      @description = description.to_s
    end

    def to_initial_request_params
      {
        name: name,
        description: description,
      }
    end
  end
end
