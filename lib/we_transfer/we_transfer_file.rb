# frozen_string_literal: true

module WeTransfer
  class WeTransferFile
    attr_reader :name, :id, :io, :multipart, :size

    # Construct a WeTransferFile
    #
    # The initializer will try its best to figure out the name and size if it
    # isn't provided, but the io can provide it.
    #
    # @param  :io [optional, anything] The io of the file. This will be wrapped
    #         in a MiniIo, or (if absent) wrapped in a NullMiniIo.
    # @param  :name [optional, String] The name you want to give your file. This
    #          does not have to match the original file name.
    # @param  :size [optional, Numeric] The size of the file. Has to be exact to
    #         the byte. If omitted, the io will be used to figure out the size
    #
    # @raise  [ArgumentError] If :name and :size arguments are empty and cannot
    #         be derived from the io.
    #
    # @example  With only an io. This will figure out the name and size of the file using MiniIo.
    #           WeTransfer::WeTransferFile.new(io: File.open('Gemfile')) # =>
    #           #<WeTransfer::WeTransferFile:0x00007fc81da25110
    #             @io=#<WeTransfer::MiniIO:0x00007fc81da250c0 @io=#<File:Gemfile>>,
    #             @name="Gemfile",
    #             @size=166
    #           >
    #
    # @example  With only a name and size.
    #           WeTransfer::WeTransferFile.new(name: 'README.md', size: 1337) # =>
    #           #<WeTransfer::WeTransferFile:0x00007fc81d0adee8
    #             @io=#<WeTransfer::NullMiniIO:0x00007fc81d24c830>,
    #             @name="README.md",
    #             @size=1337
    #           >
    #
    # @see MiniIo.name
    # @see MiniIo.size
    # @see NullMiniIo
    #
    def initialize(name: nil, size: nil, io: nil)
      @io = MiniIO.new(io)
      @name = name || @io.name
      @size = size || @io.size

      raise ArgumentError, "Need a file name and a size, or io should provide it" unless @name && @size
    end

    def as_persist_params
      {
        name: @name,
        size: @size,
      }
    end

    def to_h
      prepared = %i[name size id].each_with_object({}) do |prop, memo|
        memo[prop] = send(prop)
      end
      prepared[:multipart] = multipart.to_h

      prepared
    end
  end
end
