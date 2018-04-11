require 'spec_helper'

describe WeTransfer::Client do
  before(:each) do
    ENV['WT_API_URL'] = nil
  end

  describe '#api_key?' do
    it 'returns true if the api_bearer_token is present' do
      client = described_class.new(api_key: 'key', api_bearer_token: 'token.token')
      expect(client.api_key?).to be true
    end
    it 'returns true if the api_key is present but the token is nil' do
      client = described_class.new(api_key: 'key')
      expect(client.api_key?).to be true
    end
  end

  describe '#api_bearer_token?' do
    it 'returns true if the api_bearer_token is present' do
      client = described_class.new(api_key: "key", api_bearer_token: 'token.token')
      expect(client.api_bearer_token?).to be true
    end

    it 'returns false if the api_bearer_token is nil' do
      client = described_class.new(api_key: 'key')
      expect(client.api_bearer_token?).to be false
    end
  end

  describe '#api_url' do
    before(:each) do
      @client = described_class.new(api_key: "key")
    end

    it 'stores the proper url' do
      expect(@client.api_url).to eq("https://dev.wetransfer.com")
    end

    it 'allows the url to be reconfigured' do
      ENV['WT_API_URL'] = "https://staging-api.example.com"
      client = described_class.new(api_key: "key")
      expect(client.api_url).to eq("https://staging-api.example.com")
      ENV['WT_API_URL'] = nil
    end
  end

  describe '#api_connection' do
    before(:each) do
      @client = described_class.new(api_key: "key")
    end

    it 'creates a api_connection object' do
      expect(@client.api_connection.class).to eq(Faraday::Connection)
      expect(@client.api_connection.url_prefix.host).to eq("dev.wetransfer.com")
    end

    it 'creates a connection object with a requested url' do
      ENV['WT_API_URL'] = "https://staging-api.example.com"
      client = described_class.new(api_key: "key")
      expect(client.api_connection.class).to eq(Faraday::Connection)
      expect(client.api_connection.url_prefix.host).to eq("staging-api.example.com")
      ENV['WT_API_URL'] = nil
    end
  end
end
