# frozen_string_literal: true

require 'spec_helper'

describe WeTransfer::Client do

  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:file_locations) { %w[Japan-01.jpg Japan-02.jpg] }

  describe 'Transfers' do
    pending 'creates a transfer with multiple files' do
      fail
      transfer = client.create_transfer(message: 'Japan: 🏯 & 🎎') do |builder|
        file_locations.each do |file_location|
          builder.add_file(name: File.basename(file_location), io: File.open(fixtures_dir + file_location, 'rb'))
        end
      end

      expect(transfer).to be_kind_of(RemoteTransfer)

      # it has an url that is not available (yet)
      expect(transfer.url).to be(nil)
      # it has no files (yet)
      expect(transfer.files.first.url).to be(nil)
      # it is in an uploading state
      expect(transfer.state).to eq('uploading')

      # TODO: uncouple file_locations and transfer.files
      file_locations.each_with_index do |location, index|
        client.upload_file(
          object: transfer,
          file: transfer.files[index],
          io: File.open(fixtures_dir + location, 'rb')
        )
        client.complete_file!(
          object: transfer,
          file: transfer.files[index]
        )
      end

      result = client.complete_transfer(transfer: transfer)

      # it has an url that is available
      expect(result.url =~ %r|^https://we.tl/t-|).to be_truthy

      # it is in a processing state
      expect(result.state).to eq('processing')

      response = Faraday.get(result.url)
      # it hits the short-url with redirect
      expect(response.status).to eq(302)
      expect(response['location']).to start_with('https://wetransfer.com/')
    end
  end
end
