require 'spec_helper'

describe WeTransfer::Client do
  subject { described_class.new(params) }
  let(:params) { { api_key: ENV.fetch('WT_API_KEY') } }

  it 'exposes VERSION' do
    expect(WeTransfer::VERSION).to be_kind_of(String)
  end

  describe "#ensure_ok_status!" do
    before(:all) { Response = Struct.new(:status) }

    context "on success" do
      it "returns true if the status code is in the 2xx range" do
        (200..299).each do |status_code|
          response = Response.new(status_code)
          expect(subject.ensure_ok_status!(response)).to be_truthy
        end
      end
    end

    context "unsuccessful" do
      it "raises with the status code the server returned" do
        response = Response.new("Mehh")
        expect { subject.ensure_ok_status!(response) }
          .to raise_error(WeTransfer::Client::Error, %r/Response had a Mehh code/)
      end

      it "if there is a server error, it raises with information that we can retry" do
        (500..504).each do |status_code|
          response = Response.new(status_code)
          expect { subject.ensure_ok_status!(response) }
            .to raise_error(WeTransfer::Client::Error, /we could retry/)
        end
      end

      it "on client error, it raises with information that the server cannot understand this" do
        (400..499).each do |status_code|
          response = Response.new(status_code)
          expect { subject.ensure_ok_status!(response) }
            .to raise_error(WeTransfer::Client::Error, /server will not accept this request even if retried/)
        end
      end

      it "if the status code is unknown, it raises a generic error" do
        response = Response.new("I aint a status code")
        expect { subject.ensure_ok_status!(response) }
          .to raise_error(WeTransfer::Client::Error, /no idea what to do/)
      end
    end
  end
end
