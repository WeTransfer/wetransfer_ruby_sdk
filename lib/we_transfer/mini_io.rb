module WeTransfer
  # Wrapper around an IO object, delegating only methods we need for creating
  # and sending a file in chunks.
  #

  class MiniIO
    def self.mini_io_able?(io)
      return false if io.is_a? WeTransfer::NullMiniIO

      io.seek(0)
      io.read(1)
      io.rewind
      io.size
      true
    rescue
      false
    end

    # Make sure MiniIO does not wrap a MiniIO instance
    #
    # @param io [anything] An object that responds to #read, #rewind, #seek, #size
    #
    def self.new(io)
      return WeTransfer::NullMiniIO.instance if io.nil?
      return io if io.is_a? WeTransfer::MiniIO

      super
    end

    # Initialize with an io object to wrap
    #
    # @param io [anything] An object that responds to #read, #rewind, #seek, #size
    #
    def initialize(io)
      ensure_mini_io_able!(io)

      @io = io
      @io.rewind
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

    # The size, delegated to io.
    #
    # nil is fine, since this method is used only as the default size for a
    # WeTransferFile
    # @returns [Integer] the size of the io
    #
    def size
      @io.size
    end

    # The name of the io, guessed using File.basename. If this raises a TypeError
    # we swallow the error, since this is used only as the default name for a
    # WeTransferFile
    #
    def name
      File.basename(@io)
    rescue TypeError
      # yeah, what?
    end

    private

    def ensure_mini_io_able!(io)
      return if self.class.mini_io_able?(io)

      raise ArgumentError, "The io must respond to seek(), read(), size() and rewind(), but #{io.inspect} did not"
    end
  end

  class NullMiniIO
    require 'singleton'
    include Singleton

    instance.freeze

    def read(*); end

    def rewind; end

    def seek(*); end

    def size; end

    def name; end
  end
end