require 'spec_helper'

describe WeTransfer::Communication do
  subject(:communicator) { described_class.new('fake api key') }

  let(:fake_transfer_id) { "fake-transfer-id" }
  let(:fake_file_id) { "fake-file-id" }

  let!(:authentication_stub) {
    stub_request(:post, described_class::API_URL_BASE + described_class::AUTHORIZE_URI)
    .to_return(status: 200, body: { token: "fake-test-token" }.to_json, headers: {})
  }

  # In this test we use the call to #find_transfer. This is NOT exemplary, it serves only
  # the purpose of doing a request/response cycles to handle specific status codes (2xx, 4xx, 50x)
  describe ".ensure_ok_status!" do
    context "on a successful request" do
      let!(:find_transfer_stub) do
        stub_request(:get, "#{WeTransfer::Communication::API_URL_BASE}/v2/transfers/fake-transfer-id")
        .to_return(
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
        subject.find_transfer('fake-transfer-id')
        expect { subject.find_transfer('fake-transfer-id') }
          .to_not raise_error
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
        expect { subject.find_transfer('fake-transfer-id') }
          .to raise_error(WeTransfer::CommunicationError)
      end

      it "showing the error from the API to the user" do
        expect { subject.find_transfer('fake-transfer-id') }
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
        expect { subject.find_transfer('fake-transfer-id') }
        .to raise_error(WeTransfer::CommunicationError)
      end

      it "is telling we can try again" do
        expect { subject.find_transfer('fake-transfer-id') }
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
          expect { subject.find_transfer('fake-transfer-id') }
            .to raise_error(WeTransfer::CommunicationError)
        end

        it "includes the error code in the message" do
          expect { subject.find_transfer('fake-transfer-id') }
            .to raise_error(%r|had a 302 code|)
        end

        it "informs the user we have no way how to continue" do
          expect { subject.find_transfer('fake-transfer-id') }
            .to raise_error(%r|no idea what to do with that|)
        end
      end
    end
  end

  describe "#find_transfer" do
    let(:fake_transfer_id) { "fake-transfer-id" }

    let(:transfer_body) do
      {
        id: fake_transfer_id,
        state: "uploading",
        message: "test transfer",
        url: nil,
        files: files_stub,
        expires_at: "2019-02-28T20:00:22Z"
      }
    end

    let(:files_stub) do
      [
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
      ]
    end

    let!(:find_transfer_stub) do
      stub_request(
        :get,
        described_class::API_URL_BASE + (described_class::TRANSFER_URI % fake_transfer_id)
      )
      .to_return(
        status: 200,
        body: transfer_body.to_json,
        headers: {},
      )
    end

    it "needs a transfer_id param" do
      expect { communicator.find_transfer }
        .to raise_error(ArgumentError)
    end

    it "sends a GET to TRANSFER_URI" do
      allow(WeTransfer::Transfer)
        .to receive(:new)
        .and_return(instance_double(WeTransfer::Transfer))

      allow(communicator)
        .to receive(:setup_transfer)

      communicator.find_transfer('fake-transfer-id')

      expect(find_transfer_stub)
        .to have_been_requested
    end

    it "instantiates a WeTransfer::Transfer" do
      expect(WeTransfer::Transfer)
        .to receive(:new)
        .with(message: "test transfer", communicator: communicator)

      allow(communicator)
        .to receive(:setup_transfer)

      communicator.find_transfer('fake-transfer-id')
    end

    it "instantiates the Transfer with all expected attributes and values" do
      expected = {
        files: [
          {
            id: "fake_file_id",
            multipart: {
              chunk_size: 8,
              chunks: 1
            },
            name: "test file",
            size: 8
          }
        ],
        id: "fake-transfer-id",
        message: "test transfer",
        state: "uploading",
        url: nil
      }

      expect(communicator.find_transfer('fake-transfer-id').to_h)
        .to eq expected
    end
  end

  describe "#upload_url_for_chunk" do
    let(:chunk) { 1 }
    let(:fake_upload_url) { "https://fake.upload.url/123" }

    let!(:upload_url_stub) do
      stub_request(
        :get,
        described_class::API_URL_BASE + (
          described_class::UPLOAD_URL_URI % [fake_transfer_id, fake_file_id, chunk]
        )
      )
      .to_return(
        status: 200,
        body: { success: true, url: fake_upload_url }.to_json,
        headers: {},
      )
    end

    it "should be invoked with arguments for transfer_id, file_id and chunk" do
      expect { communicator.upload_url_for_chunk(fake_transfer_id, fake_file_id, chunk) }
        .not_to raise_error
    end

    it "returns the url from the response of the WeTransfer Public API" do
      expect(communicator.upload_url_for_chunk(fake_transfer_id, fake_file_id, chunk))
        .to eq fake_upload_url
    end
  end

  describe "#persist_transfer" do
    let!(:persist_transfer_stub) do
      stub_request(:post, described_class::API_URL_BASE + described_class::TRANSFERS_URI)
        .to_return(
          status: 200,
          body: {
            success: true,
            id: fake_transfer_id,
            state: persisted_transfer_state,
            message: "test transfer",
            url: nil,
            files: [
              {
                id: fake_file_id,
                name: "test file",
                size: 8,
                multipart: {
                  part_numbers: 1,
                  chunk_size: 8
                },
                type: "file"
              }
            ],
            expires_at: "2019-03-13T16:14:02Z"
          }.to_json,
          headers: {},
        )
    end

    let(:transfer) do
      WeTransfer::Transfer.new(
        message: 'fake transfer',
        communicator: communicator
      ).add_file(name: 'test file', size: 8)
    end

    let(:persisted_transfer_state) { "fake transfer state" }

    it "is invoked with a Transfer instance as argument" do
      # allow(transfer)
      #   .to receive(:as_persist_params)
      #   .and_return(id: fake_transfer_id)

      # allow(transfer)
      #   .to receive(:find_file_by_name)
      #   .and_return(id: fake_file_id)

      expect { communicator.persist_transfer(transfer) }
        .not_to raise_error
    end

    it "invokes :as_persist_params on the transfer" do
      # allow(transfer)
      #   .to receive(:find_file_by_name)
      #   .and_return(id: fake_file_id)

      expect(transfer)
        .to receive(:as_persist_params)
        .and_return(id: fake_transfer_id)

      communicator.persist_transfer(transfer)
    end

    it "assigns the transfer an @id, @state and @url" do
      expect(transfer)
        .to receive(:instance_variable_set)
        .with("@id", fake_transfer_id)

      expect(transfer)
        .to receive(:instance_variable_set)
        .with("@state", persisted_transfer_state)

      expect(transfer)
        .to receive(:instance_variable_set)
        .with("@url", nil)

      communicator.persist_transfer(transfer)
    end
  end

  describe "#finalize_transfer" do
    let(:transfer_url) { "https://ready.for/download" }
    let(:finalized_transfer_state) { "fake finalized state" }

    let!(:finalize_transfer_stub) do
      stub_request(:put, described_class::API_URL_BASE + (described_class::FINALIZE_URI % fake_transfer_id))
        .to_return(
          status: 200,
          body: {
            success: true,
            id: fake_transfer_id,
            state: finalized_transfer_state,
            message: "test transfer",
            url: transfer_url,
            files: [
              {
                id: fake_file_id,
                name: "test file",
                size: 8,
                multipart: {
                  part_numbers: 1,
                  chunk_size: 8
                },
                type: "file"
              }
            ],
            expires_at: "2019-03-13T16:14:02Z"
          }.to_json,
          headers: {},
        )
    end

    let(:transfer) do
      WeTransfer::Transfer.new(
        message: 'fake transfer',
        communicator: communicator
      ).add_file(name: 'test file', size: 8)
    end

    before do
      allow(transfer)
        .to receive(:id)
        .and_return(fake_transfer_id)
    end

    it "is invoked with a Transfer instance" do
      expect { communicator.finalize_transfer(transfer) }
        .not_to raise_error
    end

    it "assigns the transfer an @url" do
      allow(transfer)
        .to receive(:instance_variable_set)

      expect(transfer)
        .to receive(:instance_variable_set)
        .with("@url", transfer_url)

      communicator.finalize_transfer(transfer)
    end
  end
  describe "#remote_transfer_params"
  describe "#upload_chunk"
  describe "#complete_file"
end
