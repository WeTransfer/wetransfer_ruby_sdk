require 'spec_helper'

describe WeTransfer::RemoteLink do
  let(:params) {
    {
      id:     SecureRandom.uuid,
      url:    'http://www.wetransfer.com',
      meta:   {title:  'wetransfer.com'},
      type:   'link',
    }
  }

  describe '#initialize' do
    attributes = %i[id url type meta]

    attributes.each do |atttribute|
      it "raises an ArgumentError when #{atttribute} is missing" do
        params.delete(atttribute)
        expect {
          described_class.new(params)
        }.to raise_error ArgumentError, %r{#{atttribute}}
      end
    end
  end

  describe 'getters' do
    subject { described_class.new(params) }

    it 'responds to #type' do
      expect(subject.type).to eq 'link'
    end
  end
end
