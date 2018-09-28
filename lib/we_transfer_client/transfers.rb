module WeTransfer
  class Client
    module Transfers

      def create_transfer_and_upload_files(message:, transfer_builder_class: TransferBuilder)
        future_transfer = create_future_transfer(message: message, files: yield(transfer_builder_class.new))
        transfer = create_remote_transfer(future_transfer)
        transfer.files.each do |file|
          local_file = future_transfer.files.select { |x| x.name == file.name }.first
          upload_file(object: transfer, file: file, io: local_file.io)
          complete_file!(object: transfer, file: file)
        end
        complete_transfer(transfer: transfer)
      end

      def create_transfer(message:, transfer_builder_class: TransferBuilder)
        transfer = create_future_transfer(message: message, files: yield(transfer_builder_class.new))
        create_remote_transfer(transfer)
      end

      def complete_transfer(transfer:)
        complete_transfer_call(transfer)
      end

      def get_transfer(transfer_id:)
        request_transfer(transfer_id)
      end

      private

      def create_future_transfer(message:, files:, future_transfer_class: FutureTransfer)
        future_transfer_class.new(message: message, files: files)
      rescue LocalJumpError
        raise ArgumentError, 'No items where added to transfer'
      end

      def create_remote_transfer(xfer)
        authorize_if_no_bearer_token!
        response = faraday.post(
          '/v2/transfers',
          JSON.pretty_generate(xfer.to_request_params),
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        RemoteTransfer.new(JSON.parse(response.body, symbolize_names: true))
      end

      def complete_transfer_call(object)
        authorize_if_no_bearer_token!
        response = faraday.put(
          "/v2/transfers/#{object.id}/finalize",
          '',
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        RemoteTransfer.new(JSON.parse(response.body, symbolize_names: true))
      end

      def request_transfer(transfer_id)
        authorize_if_no_bearer_token!
        response = faraday.get(
          "/v2/transfers/#{transfer_id}",
          {},
          auth_headers.merge('Content-Type' => 'application/json')
        )
        ensure_ok_status!(response)
        RemoteTransfer.new(JSON.parse(response.body, symbolize_names: true))
      end
    end
  end
end
