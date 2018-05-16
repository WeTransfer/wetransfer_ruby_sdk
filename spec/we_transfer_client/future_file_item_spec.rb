require 'spec_helper'

describe FutureFileItem do
  it "errors if not given all required fields" do
    expect {
      FutureFileItem.new(name: "nope", local_identifier: "sorry")
    }.to raise_error(/missing keyword: io/)

    expect {
      FutureFileItem.new(io: "nope")
    }.to raise_error(/missing keyword: name/)
  end
  
  it "succeeds if given all kwargs" do
    future_file_item = FutureFileItem.new(name:"yes", io: "hello", local_identifier: "4815162342")
    expect(future_file_item).to be_kind_of(FutureFileItem)
  end 
  
  it "succeeds if not passed a local_identifier" do
    future_file_item = FutureFileItem.new(name:"yes", io: "hello")
    expect(future_file_item).to be_kind_of(FutureFileItem)
  end
  
  it "generates a local_identifier" do
    future_file_item = FutureFileItem.new(name:"who", io: "ami")
    expect(future_file_item).to be_kind_of(FutureFileItem)
    expect(future_file_item.local_identifier).to_not be nil
    expect(future_file_item.local_identifier).to be_kind_of(String)
  end
  
  it "creates params properly" do
    future_file_item = FutureFileItem.new(name:"yes", io: "hello", local_identifier: "4815162342")
    item_as_params = future_file_item.to_item_request_params
    expect(item_as_params[:content_identifier]).to eq("file")
    expect(item_as_params[:local_identifier]).to eq("4815162342")
    expect(item_as_params[:filename]).to eq("yes")
    expect(item_as_params[:filesize]).to eq(5)
  end
end

