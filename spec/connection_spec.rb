require 'spec_helper'

describe WeTransfer::Connection do
  describe 'Connection#new' do
    it 'creates a new connection when the client is passed' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      expect(connection.api_connection).to be_kind_of Faraday::Connection
    end

    it 'contains the api_key inside the connection' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      expect(connection.api_key).to be(client.api_key)
    end

    it 'requests an api bearer token on initialize' do
      # Look into openstruct
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      expect(connection.api_bearer_token).to_not be_nil
    end
  end

  describe 'Connection#post_request' do
    it 'returns with a response body when a post request is made' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      response = connection.post_request(path: '/v1/authorize')
      expect(response['status']).to eq('success')
    end

    it 'returns with a StandardError when request is forbidden' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      expect {
        connection.post_request(path: '/forbidden')
      }.to raise_error(StandardError, 'Forbidden')
    end

    it 'returns with a StandardError when user is not authorized' do
      skip
      client = OpenStruct.new(api_key: nil)
      connection = described_class.new(client: client)
      expect {
        connection.post_request(path: '/v1/authorize')
      }.to raise_error(StandardError, 'Unauthorized')
    end
  end

  describe 'Connection#get_request' do
    it 'returns with a response body when a get request is made for upload urls' do
      skip ''
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      response = connection.get_request(path: '/v1/files/1337/uploads/1/7331')
      expect(response['upload_url']).to_not be_nil?
      expect(response['part_number']).to be(1)
      expect(response['upload_id']).to_not be_nil?
      expect(response['upload_expires_at']).to_not be_nil?
    end

    it 'returns with a StandardError when request is forbidden' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      expect {
        connection.post_request(path: '/forbidden')
      }.to raise_error(StandardError, 'Forbidden')
    end

    it 'returns with a StandardError when user is not authorized' do
      skip
      client = OpenStruct.new(api_key: nil)
      connection = described_class.new(client: client)
      expect {
        connection.post_request(path: '/v1/authorize')
      }.to raise_error(StandardError, 'Unauthorized')
    end
  end
end
