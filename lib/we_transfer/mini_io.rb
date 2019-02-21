module WeTransfer
  # Wrapper around an IO object, delegating only methods we need for creating
  # and sending a file in chunks.
  #
  class MiniIO
    # Initialize with an io object to wrap
    #
    # @param io [anything] An object that responds to #read, #rewind, #seek, #size
    #
    def initialize(io)
      @io = io
    end

    def read(*args)
      @io.read(*args)
    end

    def rewind
      @io.rewind
    end

    def seek(*args)
      @io.seek(*args)
    end

    # The size delegated to io.
    # If io is nil, we return nil.
    #
    # nil is fine, since this method is used only as the default size for a
    # WeTransferFile
    # @returns [Integer, nil] the size of the io. See IO#size
    #
    def size
      @io&.size
    end

    # The name of the io, guessed using File.basename. If this raises a TypeError
    #   we swallow the error, since this is used only as the default name for a
    #   WeTransferFile
    #
    def name
      File.basename(@io)
    rescue TypeError
      # yeah, what?
    end
  end
end
