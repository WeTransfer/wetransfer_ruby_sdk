require 'spec_helper'

describe WeTransfer::Connection do
  describe 'Connection#new' do

    it 'creates a new connection when the client is passed' do
      Client = Struct.new(:api_key)
      client = Client.new('api-key-12345')
      connection = described_class.new(client: client)
      expect(connection.api_connection).to be_kind_of Faraday::Connection
    end

    it 'contains the api_key inside the connection' do
      Client = Struct.new(:api_key)
      client = Client.new('api-key-12345')
      connection = described_class.new(client: client)
      expect(connection.api_key).to be(client.api_key)
    end

    it 'requests an api bearer token on initialize' do
      Client = Struct.new(:api_key)
      client = Client.new('api-key-12345')
      connection = described_class.new(client: client)
      expect(connection.api_bearer_token).to_not be(nil)
    end
  end
end