require 'spec_helper'

describe TransferBuilder do
  it 'raises if given an item with a size of 0' do
    broken = StringIO.new('')
    expect {
      described_class.new.ensure_io_compliant!(broken)
    }.to raise_error(/The IO object given to add_file has a size of 0/)
  end

  it 'raises if IO raises an error' do
    broken = []

    expect {
      described_class.new.ensure_io_compliant!(broken)
    }.to raise_error(TransferBuilder::TransferIOError)
  end

  it 'adds a file' do
    transfer_builder = described_class.new
    transfer_builder.add_file_at(path: __FILE__)
    expect(transfer_builder.items.count).to eq(1)

    item = transfer_builder.items.first
    expect(item.name).to eq('transfer_builder_spec.rb')
    expect(item.io).to be_kind_of(File)
    expect(item.local_identifier).to be_kind_of(String)
  end

  it 'should add a url' do
    transfer_builder = described_class.new
    transfer_builder.add_web_url(url: 'https://www.wetransfer.com/')
    expect(transfer_builder.items.count).to eq(1)

    item = transfer_builder.items.first
    expect(item.url).to eq('https://www.wetransfer.com/')
    expect(item.local_identifier).to be_kind_of(String)
  end

  it 'should user url for the title when none is given' do
    transfer_builder = described_class.new
    transfer_builder.add_web_url(url: 'https://www.wetransfer.com/')
    expect(transfer_builder.items.count).to eq(1)

    item = transfer_builder.items.first

    expect(item.title).to eq('https://www.wetransfer.com/')
    expect(item.local_identifier).to be_kind_of(String)
  end

  it 'should pass title as webcontent title' do
    transfer_builder = described_class.new
    transfer_builder.add_web_url(url: 'https://www.wetransfer.com/', title: 'awesome website for file transfering')
    expect(transfer_builder.items.count).to eq(1)

    item = transfer_builder.items.first
    expect(item.url).to eq('https://www.wetransfer.com/')
    expect(item.title).to eq('awesome website for file transfering')
    expect(item.local_identifier).to be_kind_of(String)
  end
end
