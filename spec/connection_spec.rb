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

    it 'correctly handles the connection path variable' do
      ENV['WT_API_CONNECTION_PATH'] = '/this_path_does_not_exist'
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      expect(connection.api_path).to eq('/this_path_does_not_exist')
      ENV['WT_API_CONNECTION_PATH'] = '/v1'
      connection = described_class.new(client: client)
      expect(connection.api_path).to eq('/v1')
    end
  end

  describe 'Connection#post_request' do
    it 'returns with a response body when a post request is made' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      response = connection.post_request(path: '/authorize')
      expect(response['status']).to eq('success')
    end

    it 'returns with a response body when a post request is made' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      response = connection.post_request(path: '/transfers', body: {name: 'test_transfer', description: 'this is a test transfer', items: []})
      expect(response['shortened_url']).to start_with('http://we.tl/s-')
      expect(response['name']).to eq('test_transfer')
      expect(response['description']).to eq('this is a test transfer')
      expect(response['items'].count).to be(0)
    end
  end

  describe 'Connection#get_request' do
    it 'returns with a response body when a get request is made for upload urls' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      response = connection.get_request(path: '/files/1337/uploads/1/7331')
      expect(response['upload_url']).to include('upload')
      expect(response['part_number']).to be(1)
      expect(response['upload_id']).to_not be_nil
      expect(response['upload_expires_at']).to_not be_nil
    end

    it 'returns with a StandardError when request is forbidden' do
      client = OpenStruct.new(api_key: 'api-key-12345')
      connection = described_class.new(client: client)
      expect {
        connection.post_request(path: '/forbidden')
      }.to raise_error(StandardError, 'Forbidden')
    end
  end
end
