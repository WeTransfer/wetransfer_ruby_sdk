class RemoteTransfer
  attr_reader :files, :url, :state, :id

  def initialize(id:, state:, url:, message:, files: [])
    @id = id
    @state = state
    @message = message
    @url = url
    @files = files_to_class(files)
  end

  def files_to_class(files)
    files.map { |x| RemoteFile.new(x) }
  end
end
