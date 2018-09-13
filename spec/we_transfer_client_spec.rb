require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransferClient do
  it 'exposes VERSION' do
    expect(WeTransferClient::VERSION).to be_kind_of(String)
  end

  describe '#initialize' do
    let (:params) {
      { api_key: ENV.fetch('WT_API_KEY') }
    }
    let (:object) {
      described_class.new(params)
    }
    it 'creates a new instance' do
      object
    end


  end
end
