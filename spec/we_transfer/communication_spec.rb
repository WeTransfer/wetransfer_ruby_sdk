require 'spec_helper'

describe WeTransfer::Communication do
  before { described_class.logger = Logger.new(nil) }

  # In this test we use the call to #find_transfer. This is NOT exemplary, it serves only
  # the purpose of doing a request/response cycle to handle specific status codes (2xx, 4xx, 50x)
  context ".ensure_ok_status!" do

    let!(:authentication_stub) {
      stub_request(:post, "#{WeTransfer::Communication::API_URL_BASE}/v2/authorize")
      .to_return(status: 200, body: {token: "fake-test-token"}.to_json, headers: {})
    }

    context "on a successful request" do
      let!(:find_transfer_stub) do
        stub_request(:get, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers/fake-transfer-id").
        to_return(
          status: 200,
          body: {
            id: "24cd3f4ccf15232e5660052a3688c03f20190221200022",
            state: "uploading",
            message: "test transfer",
            url: nil,
            files: [
              {
                id: "fake_file_id",
                name: "test file",
                size: 8,
                multipart: {
                  part_numbers: 1,
                  chunk_size: 8
                },
                type: "file",
              }
            ],
            expires_at: "2019-02-28T20:00:22Z",
          }.to_json,
          headers: {},
        )
      end

      it "does not raise a CommunicationError" do
        expect { described_class.find_transfer('fake-transfer-id') }
        .to_not raise_error(WeTransfer::CommunicationError)
      end
    end

    context "on a client error" do
      let!(:find_transfer_stub) do
        stub_request(:get, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers/fake-transfer-id").
        to_return(
          status: 405,
          body: '{
            "success":false,
            "message":"fake message"
          }',
          headers: {},
        )
      end

      it "raises a CommunicationError" do
        expect { described_class.find_transfer('fake-transfer-id') }
        .to raise_error(WeTransfer::CommunicationError)
      end

      it "showing the error from the API to the user" do
        expect { described_class.find_transfer('fake-transfer-id') }
        .to raise_error('fake message')
      end
    end

    context "on a server error" do
      let!(:find_transfer_stub) do
        stub_request(:get, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers/fake-transfer-id").
        to_return(
          status: 501,
          body: '',
          headers: {},
        )
      end

      it "raises a CommunicationError" do
        expect { described_class.find_transfer('fake-transfer-id') }
        .to raise_error(WeTransfer::CommunicationError)
      end

      it "is telling we can try again" do
        expect { described_class.find_transfer('fake-transfer-id') }
          .to raise_error(%r|had a 501 code.*could retry|)
      end

      context "everything else" do
        let(:find_transfer_stub) do
          stub_request(:get, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers/fake-transfer-id").
          to_return(
            status: 302,
            body: '',
            headers: {},
          )
        end

        it "raises a CommunicationError" do
          expect { described_class.find_transfer('fake-transfer-id') }
            .to raise_error(WeTransfer::CommunicationError)
        end

        it "includes the error code in the message" do
          expect { described_class.find_transfer('fake-transfer-id') }
            .to raise_error(%r|had a 302 code|)
        end

        it "informs the user we have no way how to continue" do
          expect { described_class.find_transfer('fake-transfer-id') }
            .to raise_error(%r|no idea what to do with that|)
        end
      end
    end
  end
end
