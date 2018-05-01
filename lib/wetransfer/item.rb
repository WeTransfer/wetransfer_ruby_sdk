module WeTransfer
  class Item
    attr_accessor :id,
                  :content_identifier,
                  :local_identifier,
                  :multipart_parts,
                  :multipart_id,
                  :name,
                  :size,
                  :upload_url,
                  :upload_id,
                  :path
  end
end
