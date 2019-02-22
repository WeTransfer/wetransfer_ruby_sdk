module WeTransfer
  module RemoteFile
    class FileMismatchError < StandardError; end
    class NoIoError < StandardError; end

    class Multipart < ::Ks.strict(:chunks, :chunk_size)
      def to_h
        %i[chunks chunk_size].each_with_object({}) do |prop, memo|
          memo[prop] = send(prop)
        end
      end
    end

    def self.upgrade(files_response:, transfer:)
      files_response.each do |file_response|
        local_file = transfer.find_file_by_name(file_response[:name])

        local_file.instance_variable_set(
          :@id,
          file_response[:id]
        )

        local_file.instance_variable_set(
          :@multipart,
          Multipart.new(
            chunks: file_response[:multipart][:part_numbers],
            chunk_size: file_response[:multipart][:chunk_size],
          )
        )
      end
    end
  end
end
