class FutureFileItem < Ks.strict(:name, :io, :local_identifier)
  def initialize(**kwargs)
    super(local_identifier: SecureRandom.uuid, **kwargs)
  end

  def to_item_request_params
    # Ideally the content identifier should stay the same throughout multiple
    # calls if the file contents doesn't change.
    {
      content_identifier: 'file',
      local_identifier: local_identifier,
      filename: name,
      filesize: io.size,
    }
  end
end
