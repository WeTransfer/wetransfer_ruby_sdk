# require 'spec_helper'

# describe WeTransfer::Transfers do
#   context 'without a client' do
#     it 'throws an error' do
#       expect {
#         described_class.new('1')
#       }.to raise_error(/Not a WeTransfer client!/)
#     end
#   end

#   context 'with a client' do
#     before(:all) do
#       ENV['WT_API_URL'] = 'http://localhost:9001'
#       @client = WeTransfer::Client.new(api_key: 'sample-key')
#       WeTransfer::Authorizer.new(@client).request_jwt
#     end

#     after(:all) do
#       ENV['WT_API_URL'] = ''
#     end

#     it 'has a bearer token' do
#       expect(@client.api_bearer_token).to_not be nil
#     end

#     it 'creates a transfer without items' do
#       transfer = described_class.new(@client).create_new_transfer(name: 'Noah',
#         description: 'has a test transfer')

#       expect(transfer.id).to_not be nil
#       expect(transfer.name).to eq('Noah')
#       expect(transfer.description).to eq('has a test transfer')
#       expect(transfer.shortened_url).to_not be nil
#       expect(transfer.items).to eq([])
#     end

#     it 'creates a transfer with item listings' do
#       transfer = described_class.new(@client).create_new_transfer(name: 'Noah',
#         description: 'has a test transfer',
#         items: [{cool: 'great'}])

#       expect(transfer.id).to_not be nil
#       expect(transfer.name).to eq('Noah')
#       expect(transfer.description).to eq('has a test transfer')
#       expect(transfer.shortened_url).to_not be nil
#       expect(transfer.items).to eq([{'cool' => 'great'}])
#     end

#     it 'creates a transfer with files and returns the file information' do
#       skip
#       transfer = described_class.new(@client).create_new_transfer(name: 'foo',
#         description: 'bar', items: [{local_identifier: 'qux', content_identifier: 'file', filename: 'quux', filesize: 1024}])

#       expect(transfer.id).to_not be(nil)
#       expect(transfer.name).to eq('foo')
#       expect(transfer.description).to eq('bar')
#       expect(transfer.shortened_url).to be_present?
#       expect(tramsfer.items.count).to eq(1)
#       expect(transfer.items['content_identifier']).to be('qux')
#       expect(transfer.items['meta']).to be_present?
#       expect(transfer.items['upload_url']).to be_present?
#       expect(transfer.items['size']).to be(1024)
#     end

#     it 'creates a transfer with a multipart file and returns the multipart information' do
#       skip
#       transfer = described_class.new(@client).create_new_transfer(name: 'foo',
#         description: 'bar', items: [{local_identifier: 'qux', content_identifier: 'file', filename: 'quux', filesize: 8_435_376}])

#       expect(transfer.id).to_not be(nil)
#       expect(transfer.name).to eq('foo')
#       expect(transfer.description).to eq('bar')
#       expect(transfer.shortened_url).to be_present?
#       expect(tramsfer.items.count).to eq(1)
#       expect(transfer.items['content_identifier']).to be('qux')
#       expect(transfer.items['meta']['multipart_parts']).to eq(2)
#       expect(transfer.items['size']).to be(8_435_376)
#     end

#     it 'should add more items to the transfer' do
#       skip
#       transfer = described_class.new(@client).create_new_transfer(name: 'foo',
#         description: 'bar', items: [{local_identifier: 'qux', content_identifier: 'file', filename: 'quux', filesize: 8_435_376}])
#       expect(transfer.items.size).to be(1)

#       transfer = described_class.new(@client).add_items(transfer: transfer, items: [{local_identifier: 'qux', content_identifier: 'file', filename: 'quux', filesize: 8_435_376}])
#       expect(transfer.items.size).to be(2)
#     end
#   end
# end
