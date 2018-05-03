require 'spec_helper'

describe WeTransfer::ItemBuilder do

  describe 'ItemBuilder process' do
    let(:item_builder) {described_class.new}

    it 'makes a new Item if no item is given on initialze' do
      expect(item_builder).to be_an_instance_of(WeTransfer::ItemBuilder)
      expect(item_builder.item).to be_an_instance_of(WeTransfer::Item)
    end

    it 'uses the item, when a item is given to the ItemBuilder' do
      builder_item = described_class.new(item: item_builder.item)
      expect(builder_item).to be_an_instance_of(WeTransfer::ItemBuilder)
      expect(builder_item.item).to be_an_instance_of(WeTransfer::Item)
    end

    it 'sets the path when path method is called' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      expect(item_builder.item.path).to eq("#{__dir__}/war-and-peace.txt")
    end

    it 'sets content always to file' do
      item_builder.content_identifier
      expect(item_builder.item.content_identifier).to eq('file')
    end

    it 'sets the local local_identifier to the first 36 characters of the file name' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      item_builder.local_identifier
      expect(item_builder.item.local_identifier).to eq('war-and-peace.txt')
      expect(item_builder.item.local_identifier.length).to be <= 36
    end

    it 'sets the local local_identifier to the first 36 characters of the file name' do
      item_builder.path(path: "#{__dir__}/war-and-peace-and-peace-and-war-and-war-and-peace.txt")
      item_builder.local_identifier
      expect(item_builder.item.local_identifier).to eq('war-and-peace-and-peace-and-war-and-')
      expect(item_builder.item.local_identifier.length).to be <= 36
    end

    it 'sets the item name according to the given path' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      item_builder.name
      expect(item_builder.item.name).to eq('war-and-peace.txt')
    end

    it 'sets the filesize by reading the file' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      item_builder.size
      expect(item_builder.item.size).to_not be_nil
      expect(item_builder.item.size).to eq(485192)
    end

    it 'sets the id according to the api response' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      item_builder.id(item: item_builder.item, id: 1234)
      expect(item_builder.item.id).to eq(1234)
    end

    it 'sets the upload url according to the api response' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      item_builder.upload_url(item: item_builder.item, url: "#{ENV.fetch('WT_API_URL')}/upload/#{SecureRandom.hex(9)}")
      expect(item_builder.item.upload_url).to_not be_nil
    end

    it 'sets the multipart_parts according to the api response' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      item_builder.multipart_parts(item: item_builder.item, part_count: 3)
      expect(item_builder.item.multipart_parts).to eq(3)
    end

    it 'sets the multipart_id according to the api response' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      item_builder.multipart_id(item: item_builder.item, multi_id: 1234567890)
      expect(item_builder.item.multipart_id).to eq(1234567890)
    end

    it 'sets the upload_id according to the api response' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      item_builder.upload_id(item: item_builder.item, upload_id: 1234567890)
      expect(item_builder.item.upload_id).to eq(1234567890)
    end

    it 'returns the item object when ItemBuilder item method is calles' do
      item_builder.path(path: "#{__dir__}/war-and-peace.txt")
      expect(item_builder.item).to be_an_instance_of(WeTransfer::Item)
    end

    it 'validates the file if it exists on the path given' do
      expect{
        item_builder.path(path: "#{__dir__}/war-and-peace.txt")
        item_builder.validate_file
      }.to_not raise_error(WeTransfer::ItemBuilder::FileDoesNotExistError, "#{item_builder.item} does not exist")
    end

    it 'validates the file if it exists on the path given and returns with FileDoesNotExistError' do
      expect{
        item_builder.path(path: "#{__dir__}/peace-and-war.txt")
        item_builder.validate_file
      }.to raise_error(WeTransfer::ItemBuilder::FileDoesNotExistError, "#{item_builder.item} does not exist")
    end
  end
end