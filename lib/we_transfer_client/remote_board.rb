class RemoteBoard
  ItemTypeError = Class.new(NameError)

  attr_reader :id, :items, :url, :state

  CHUNK_SIZE = 6 * 1024 * 1024

  def initialize(id:, state:, url:, name:, description: '', items: [])
    @id = id
    @state = state
    @url = url
    @name = name
    @description = description
    @items = to_instances(items: items)
  end

  def prepare_file_upload(client:, file:, part_number:)
    url = file.request_board_upload_url(client: client, board_id: @id, part_number: part_number)
    [url, CHUNK_SIZE]
  end

  def prepare_file_completion(client:, file:)
    file.complete_board_file(client: client, board_id: @id)
  end

  def file_items
    @items.select { |item| item.class == RemoteFile }
  end

  def link_items
    @items.select { |item| item.class == RemoteLink }
  end

  private

  def to_instances(items:)
    items.map do |item|
      begin
        remote_class = "Remote#{item[:type].capitalize}"
        Module.const_get(remote_class)
          .new(item)
      rescue NameError
        raise ItemTypeError, "Cannot instantiate item with type '#{item[:type]}' and id '#{item[:id]}'"
      end
    end
  end
end
