class FutureWebItem < Ks.strict(:url, :title, :local_identifier)
  def initialize(**kwargs)
    super(local_identifier: SecureRandom.uuid, **kwargs)
  end

  def to_item_request_params
    # Ideally the content identifier should stay the same throughout multiple
    # calls if the file contents doesn't change.
    {
      content_identifier: 'web_content',
      local_identifier: local_identifier,
      url: url,
      meta: {
        title: title
      }
    }
  end
end
