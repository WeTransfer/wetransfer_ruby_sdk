require 'spec_helper'

describe FutureWebItem do
  it 'errors if not given all required arguments' do
    expect {
      described_class.new(url: 'http://www.wetransfer.com', local_identifier: '321235151')
    }.to raise_error(/missing keyword: title/)

    expect {
      described_class.new(title: 'wetransfer.com')
    }.to raise_error(/missing keyword: url/)
  end

  it 'succeeds if given all arguments' do
    future_web_item = described_class.new(url: 'http://www.wetransfer.com', title: 'wetransfer.com', local_identifier: '321235151')
    expect(future_web_item).to be_kind_of(FutureWebItem)
  end

  it 'succeeds if not passed a local_identifier' do
    future_web_item = described_class.new(url: 'http://www.wetransfer.com', title: 'wetransfer.com')
    expect(future_web_item).to be_kind_of(FutureWebItem)
  end

  it 'generates a local_identifier' do
    future_web_item = described_class.new(url: 'http://www.wetransfer.com', title: 'wetransfer.com')
    expect(future_web_item).to be_kind_of(FutureWebItem)
    expect(future_web_item.local_identifier).to_not be nil
    expect(future_web_item.local_identifier).to be_kind_of(String)
  end

  it 'creates params properly' do
    future_web_item = described_class.new(url: 'http://www.wetransfer.com', title: 'wetransfer.com')
    item_as_params = future_web_item.to_item_request_params
    expect(item_as_params[:content_identifier]).to eq('web_content')
    expect(item_as_params[:local_identifier]).to be_kind_of(String)
    expect(item_as_params[:url]).to eq('http://www.wetransfer.com')
    expect(item_as_params[:meta][:title]).to eq('wetransfer.com')
  end
end
