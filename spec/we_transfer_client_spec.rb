require 'spec_helper'

require_relative '../lib/we_transfer_client.rb'

describe WeTransferClient do
  it 'exposes VERSION' do
    expect(WeTransferClient::VERSION).to be_kind_of(String)
  end

end