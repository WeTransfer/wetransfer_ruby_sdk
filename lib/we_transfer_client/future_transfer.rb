class FutureTransfer
  attr_accessor :message, :files

  def initialize(message:, files: [])
    @message = message
    @files = files
  end

  def as_json_request_params
    {
      message: message,
      files: files.map(&:as_json_request_params),
    }
  end
end
