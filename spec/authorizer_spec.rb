require 'spec_helper'

describe WeTransfer::Authorizer do
  context 'without a client' do
    it 'throws an error' do
      expect {
        described_class.new('1')
      }.to raise_error(/Not a WeTransfer client!/)
    end
  end

  context 'with a client' do
    before(:all) do
      ENV['WT_API_URL'] = 'http://localhost:9001'
      @client = WeTransfer::Client.new(api_key: 'sample-key')
    end

    it 'requests a jwt' do
      described_class.new(@client).request_jwt
      expect(@client.api_bearer_token).to_not be nil
    end
  end
end
