class TransferBuilder
  attr_reader :items
  class TransferIOError < StandardError; end

  def initialize
    @items = []
  end

  def add_file(name:, io:)
    ensure_io_compliant!(io)
    @items << FutureFileItem.new(name: name, io: io)
    true
  end

  def add_file_at(path:)
    add_file(name: File.basename(path), io: File.open(path, 'rb'))
  end

  def add_web_content(url:)
    @items << FutureWebItem.new(url: url, title: url)
    true
  end

  def ensure_io_compliant!(io)
    io.seek(0)
    io.read(1) # Will cause things like Errno::EACCESS to happen early, before the upload begins
    io.seek(0) # Also rewinds the IO for later uploading action
    size = io.size # Will cause a NoMethodError
    raise TransferIOError, 'The IO object given to add_file has a size of 0' if size <= 0
  rescue NoMethodError
    raise TransferIOError, "The IO object given to add_file must respond to seek(), read() and size(), but #{io.inspect} did not"
  end
end
