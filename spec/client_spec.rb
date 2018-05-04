require 'spec_helper'

describe WeTransfer::Client do
  describe 'Client#new' do
    it 'returns a error when no api_key is given' do
      expect {
        described_class.new
      }.to raise_error(ArgumentError, /missing keyword: api_key/)
    end

    it 'on initialization a active connection object is created' do
      client = described_class.new(api_key: 'api-key')
      expect(client.api_connection).to be_kind_of WeTransfer::Connection
    end
  end

  describe 'Client#create_transfer' do
    let(:client) { described_class.new(api_key: 'api-key') }

    it 'create transfer should return a transfer object' do
      transfer = client.create_transfer
      expect(transfer.shortened_url).to start_with('http://we.tl/s-')
      expect(transfer).to be_kind_of WeTransfer::Transfer
    end

    it 'when no name/description is send, a default name/description is generated' do
      transfer = client.create_transfer
      expect(transfer.name).to eql("File Transfer: #{Time.now.strftime('%d-%m-%Y')}")
      expect(transfer.description).to eql('Transfer generated with WeTransfer Ruby SDK')
    end

    it 'when a name/description is send, transfer has that name/description' do
      transfer = client.create_transfer(
        name: 'WeTransfer Test Transfer',
        description: "Moving along… Good news, everyone! I've
        taught the toaster to feel love! Humans dating robots is
        sick. You people wonder why I'm still single? It's 'cause
        all the fine robot sisters are dating humans!")
      expect(transfer.name).to eql('WeTransfer Test Transfer')
      expect(transfer.description).to start_with('Moving along… Good news, everyone!')
    end

    it 'when no items are send, a itemless transfer is created' do
      transfer = client.create_transfer
      expect(transfer.items).to be_empty
    end

    it 'when items are sended, the transfer has items' do
      transfer = client.create_transfer(items: ["#{__dir__}/war-and-peace.txt"])
      expect(transfer).to be_kind_of WeTransfer::Transfer
      expect(transfer.items.count).to be(1)
    end

    it 'returns an error when items are not sended inside an array' do
      expect {
        client.create_transfer(items: "#{__dir__}/war-end-peace.txt")
      }.to raise_error(StandardError, 'The items field must be an array')
    end

    it 'completes a item after item upload' do
      transfer = client.create_transfer(items: ["#{__dir__}/war-and-peace.txt"])
      expect(transfer).to be_kind_of WeTransfer::Transfer
    end
  end

  describe 'Client#add_item' do
    let(:client) { described_class.new(api_key: 'api-key') }

    it 'add items to an already created transfer' do
      transfer = client.create_transfer
      expect(transfer.items.count).to be(0)
      transfer = client.add_items(transfer: transfer, items: ["#{__dir__}/war-and-peace.txt"])
      expect(transfer.items.count).to be(1)
    end

    it 'raises an error when no transfer is being send to add_items_to_transfer method' do
      expect {
        client.add_items(items: ["#{__dir__}/war-and-peace.txt"])
        }.to raise_error(ArgumentError, 'missing keyword: transfer')
    end
  end
end