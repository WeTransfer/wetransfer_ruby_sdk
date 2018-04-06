require 'spec_helper'

describe WeTransfer::Client do
  describe '#credentials?' do
    it 'returns true if all credentials are present' do
      client = described_class.new(api_key: 'key', api_bearer_token: 'token.token')
      expect(client.credentials?).to be true
    end

    it 'returns false if any credentials are missing' do
      client = described_class.new(api_bearer_token: 'token.token')
      expect(client.credentials?).to be false
      client = described_class.new(api_key: 'key')
      expect(client.credentials?).to be false
    end

    it 'returns false if any credentials are blank' do
      client = described_class.new(api_key: "", api_bearer_token: 'token.token')
      expect(client.credentials?).to be false
      client = described_class.new(api_key: 'key', api_bearer_token: "")
      expect(client.credentials?).to be false
    end
  end

  describe '#api_key?' do
    it 'returns true if the api_bearer_token is present' do
      client = described_class.new(api_key: 'key', api_bearer_token: 'token.token')
      expect(client.api_key?).to be true
    end
    it 'returns true if the api_key is present but the token is not' do
      client = described_class.new(api_key: 'key')
      expect(client.api_key?).to be true
    end
    it 'returns false if the api_key is missing' do
      client = described_class.new(api_bearer_token: 'token.token')
      expect(client.api_key?).to be false
    end
  end

  describe '#api_bearer_token?' do
    it 'returns true if the api_bearer_token is present' do
      client = described_class.new(api_key: "key", api_bearer_token: 'token.token')
      expect(client.api_bearer_token?).to be true
    end
    it 'returns true if the api_bearer_token is present but the key is not' do
      client = described_class.new(api_bearer_token: 'token.token')
      expect(client.api_bearer_token?).to be true
    end
    it 'returns false if the api_bearer_token is missing' do
      client = described_class.new(api_key: 'key')
      expect(client.api_bearer_token?).to be false
    end
  end
end
