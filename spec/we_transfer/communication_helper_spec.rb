require 'spec_helper'

describe WeTransfer::Communication do
  context ".ensure_ok_status!" do
    subject { described_class }

    before { pending }

    before(:all) do
      Response = Struct.new(:status, :body)
      WeTransfer::Communication.logger = Logger.new(nil)
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
          .to raise_error(WeTransfer::CommunicationError, %r/Response had a 404 code/)

        response = Response.new("Meh")
        expect { subject.ensure_ok_status!(response) }
          .to raise_error(WeTransfer::CommunicationError, %r/Response had a Meh code/)
      end

      it "if there is a server error, it raises with information that we can retry" do
        (500..504).each do |status_code|
          response = Response.new(status_code)
          expect { subject.ensure_ok_status!(response) }
            .to raise_error(WeTransfer::CommunicationError, /we could retry/)
        end
      end

      it "on client error, it raises with information that the server responded" do
        (400..499).each do |status_code|
          response = Response.new(status_code, { "message" => 'this is a test' }.to_json)
          expect { subject.ensure_ok_status!(response) }
            .to raise_error(WeTransfer::CommunicationError, 'this is a test')
        end
      end

      it "if the status code is unknown, it raises a generic error" do
        response = Response.new("I'm no status code")
        expect { subject.ensure_ok_status!(response) }
          .to raise_error(WeTransfer::CommunicationError, /no idea what to do/)
      end
    end
  end
end
