require 'spec_helper'

describe RemoteLink do
  let (:params) {
    {
      id:     SecureRandom.uuid,
      url:    'http://www.wetransfer.com',
      title:  'wetransfer.com',
      type:   'web_content',
    }
  }

  describe '#initialize' do
    ATTRIBUTES = %i[id url title type]

    ATTRIBUTES.each do |atttribute|
      it "raises an ArgumentError when #{atttribute} is missing" do
        params.delete(atttribute)
        expect {
          described_class.new(params)
        }.to raise_error ArgumentError, %r{#{atttribute}}
      end
    end
  end

  describe 'getters' do
    subject {described_class.new(params)}

    it 'responds to #type' do
      expect(subject.type).to eq 'web_content'
    end
  end
end
