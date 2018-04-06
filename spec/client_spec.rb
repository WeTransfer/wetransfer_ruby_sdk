require 'spec_helper'

describe WeTransfer::Client do
  describe '#credentials?' do
    it 'returns true if all credentials are present' do
      client = described_class.new(api_key: 'key')
      expect(client.api_key?).to be true
    end
  end
end
