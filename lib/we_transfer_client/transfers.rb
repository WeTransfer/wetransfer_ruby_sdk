module WeTransfer
  class Client
    module Transfers
      # TODO: Make message optional, spec it
      def create_transfer(message:)
        builder = TransferBuilder.new
        yield(builder)
        future_transfer = FutureTransfer.new(message: message, files: builder.items)
        create_remote_transfer(future_transfer)
      rescue LocalJumpError
        raise ArgumentError, 'No files were added to transfer'
      end

      def complete_transfer(transfer:)
        complete_transfer_call(transfer)
      end

      def get_transfer(transfer_id:)
        request_transfer(transfer_id)
      end

      private

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
