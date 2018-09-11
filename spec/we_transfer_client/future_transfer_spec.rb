require 'spec_helper'

describe FutureTransfer do
  it 'errors if not given all required arguments' do
    skip
    expect {
      described_class.new(name: 'nope', description: 'sorry')
    }.to raise_error(/missing keyword: items/)

    expect {
      described_class.new(description: 'lol', items: [])
    }.to raise_error(/missing keyword: name/)

    expect {
      described_class.new(name: 'lol', items: [])
    }.to raise_error(/missing keyword: description/)
  end

  it 'succeeds if given all required arguments' do
    skip
    future_transfer = described_class.new(name: 'frank', description: 'a decent bloke', items: [])
    expect(future_transfer).to be_kind_of(FutureTransfer)
  end
end
