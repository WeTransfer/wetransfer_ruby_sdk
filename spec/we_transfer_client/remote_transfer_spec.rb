require 'spec_helper'

describe WeTransfer::RemoteTransfer do
  before do
    skip
  end
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger) }
  let(:params) {
    {
      id: '2ae97886522f375c1c6696799a56f0d820180912075119',
      state: 'uploading',
      message: 'Test transfer',
      url: nil,
      files:
        [
          {
            id: '5e3823ea8ad54f259c85b776eaf7086e20180912075119',
            name: 'transfer_integration_spec.rb',
            size: 7361,
            multipart: {part_numbers: 1, chunk_size: 7361},
            type: 'file',
          },
          {
            id: '43b5a6323102eced46f071f2db9ec2eb20180912075119',
            name: 'two_chunks',
            size: 6291460,
            multipart: {part_numbers: 2, chunk_size: 5242880},
            type: 'file',
          }
        ],
      client: client
    }
  }

  describe '#initialize' do
    it 'fails when id is missing' do
      params.delete(:id)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /id/
    end

    it 'fails when state is missing' do
      params.delete(:state)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /state/
    end

    it 'fails when message is missing' do
      params.delete(:message)
      expect {
        described_class.new(params)
      }.to raise_error ArgumentError, /message/
    end

    it 'fails when files is a string' do
      params.delete(:files)
      params[:files] = 'Not an array'
      expect {
        described_class.new(params)
      }.to raise_error NoMethodError
    end
  end

  describe '#instantiate_files' do
    it 'creates classes of remote files' do
      transfer = described_class.new(params)
      expect(transfer.files.map(&:class)).to eq([WeTransfer::RemoteFile, WeTransfer::RemoteFile])
    end
  end

  describe '#prepare_file_upload' do
    # pending 'it retreives the upload url' do
    #   # fail
    # end
  end

  describe 'getters' do
    %i[files urls id state].each do |getter|
      it "responds to ##{getter}" do
        subject.send getter
      end
    end
  end
end
