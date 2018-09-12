class FutureLink
  attr_reader :url, :title

  def initialize(url:, title: url)
    @url = url
    @title = title
  end

  def to_request_params
    {
      url: url,
      title: title,
    }
  end

  def name
    ''
  end
end
