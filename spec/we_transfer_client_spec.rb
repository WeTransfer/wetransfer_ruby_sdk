require 'spec_helper'

describe WeTransfer::Client do
  subject(:client) { described_class.new(params) }
  let(:params) { { api_key: ENV.fetch('WT_API_KEY') } }

  it 'has a VERSION' do
    expect(WeTransfer::VERSION).to be_kind_of(String)
  end

  describe "#get_transfer" do
    let!(:authentication_stub) {
      stub_request(:post, "#{WeTransfer::CommunicationHelper::API_URI_BASE}/v2/authorize")
        .to_return(status: 200, body: {token: 'test-token'}.to_json, headers: {})
    }

    it "requests a transfer by its id" do
      get_transfer_stub = stub_request(:get, "#{WeTransfer::CommunicationHelper::API_URI_BASE}/v2/transfers/meh")
        .to_return(
          status: 200,
          body: {
            id: "meh",
            state: "testState" ,
            url: "we.tl/t-12345",
            message: "All The Meh",
          }.to_json,
          headers: {},
        )
      client.get_transfer(transfer_id: 'meh')

      expect(authentication_stub).to have_been_requested
      expect(get_transfer_stub).to have_been_requested
    end
  end

  describe "#ensure_ok_status!" do
    before do
      skip
      Response = Struct.new(:status)
    end

    context "on success" do
      it "returns true if the status code is in the 2xx range" do
        (200..299).each do |status_code|
          response = Response.new(status_code)
          expect(subject.ensure_ok_status!(response)).to be_truthy
        end
      end
    end

    context "unsuccessful" do
      it "raises with a message including the status code the server returned" do
        response = Response.new("404")
        expect { subject.ensure_ok_status!(response) }
          .to raise_error(WeTransfer::Client::Error, %r/Response had a 404 code/)

        response = Response.new("Meh")
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
            .to raise_error(WeTransfer::Client::Error)
        end
      end

      it "if the status code is unknown, it raises a generic error" do
        response = Response.new("I am no status code")
        expect { subject.ensure_ok_status!(response) }
          .to raise_error(WeTransfer::Client::Error, /no idea what to do/)
      end
    end
  end
end
