class TransferBuilder
  attr_reader :items
  class TransferIOError < StandardError; end

  Error = Class.new(StandardError)

  DOWNLOAD_ERRORS = [
    SocketError,
    OpenURI::HTTPError,
    RuntimeError,
    URI::InvalidURIError,
    Error,
  ]


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

  def add_file_from_url(path:)
    image_path = download(path)
    add_file(name: File.basename(image_path), io: File.open(image_path, 'rb'))
  end

  def add_web_content(path:)
    url = open(path, allow_redirections: :safe).base_uri.to_s
    url_title = url.split('/').last
    @items << FutureWebItem.new(url: url, title: url_title)
    true
  end

  # def save_to_file(path:)
  #   # allow_redirection is needed to support http -> https redirection
  #   download(path)
  #   open(path, allow_redirections: :safe) do |file|
  #     file_name = file.base_uri.to_s.split('/').last
  #     extension = file.base_uri.to_s.split('.').last
  #     raise TransferIOError, 'No content size detected' if file.meta['content-length'].nil?
  #     t = Tempfile.new([file_name, ".#{extension}"] )
  #     t.write(file.read)
  #     t.close
  #     t.path
  #   end
  # end

  def ensure_io_compliant!(io)
    io.seek(0)
    io.read(1) # Will cause things like Errno::EACCESS to happen early, before the upload begins
    io.seek(0) # Also rewinds the IO for later uploading action
    size = io.size # Will cause a NoMethodError
    raise TransferIOError, 'The IO object given to add_file has a size of 0' if size <= 0
  rescue NoMethodError
    raise TransferIOError, "The IO object given to add_file must respond to seek(), read() and size(), but #{io.inspect} did not"
  end

  def download(url, max_size: 2_147_483_648)
    url = URI.encode(URI.decode(url))
    url = URI(url)
    raise Error, "url was invalid" if !url.respond_to?(:open)

    options = {}
    options["User-Agent"] = "WeTransferRubySDK/#{WeTransferClient::VERSION}"
    options[:content_length_proc] = ->(size) {
      if max_size && size && size > max_size
        raise Error, "file is too big (max is #{max_size})"
      end
    }

    downloaded_file = url.open(options)

    if downloaded_file.is_a?(StringIO)
      file_name = downloaded_file.base_uri.to_s.split('/').last
      extension = downloaded_file.base_uri.to_s.split('.').last
      tempfile = Tempfile.new([file_name, ".#{extension}"], binmode: true)
      IO.copy_stream(downloaded_file, tempfile.path)
      downloaded_file = tempfile
      # OpenURI::Meta.init downloaded_file, stringio
   end

    downloaded_file
  rescue *DOWNLOAD_ERRORS => error
    raise if error.instance_of?(RuntimeError) && error.message !~ /redirection/
    raise Error, "download failed (#{url}): #{error.message}"
  end
end
