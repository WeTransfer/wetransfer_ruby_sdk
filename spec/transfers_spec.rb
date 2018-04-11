require 'spec_helper'

describe WeTransfer::Transfers do
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
      WeTransfer::Authorizer.new(@client).request_jwt
    end

    after(:all) do
      ENV['WT_API_URL'] = ''
    end

    it 'has a bearer token' do
      expect(@client.api_bearer_token).to_not be nil
    end

    it 'creates a transfer without items' do
      transfer = described_class.new(@client).create_new_transfer(name: 'Noah', description: 'has a test transfer')
      expect(transfer.id).to_not be nil
      expect(transfer.name).to eq('Noah')
      expect(transfer.description).to eq('has a test transfer')
      expect(transfer.shortened_url).to_not be nil
      expect(transfer.items).to eq([])
    end

    it 'creates a transfer with item listings' do
      transfer = described_class.new(@client).create_new_transfer(name: 'Noah', description: 'has a test transfer', items: [{cool: 'great'}])
      expect(transfer.id).to_not be nil
      expect(transfer.name).to eq('Noah')
      expect(transfer.description).to eq('has a test transfer')
      expect(transfer.shortened_url).to_not be nil
      expect(transfer.items).to eq([{'cool' => 'great'}])
    end
  end
end
