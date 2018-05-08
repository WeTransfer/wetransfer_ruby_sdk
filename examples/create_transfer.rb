#require_relative '../lib/wetransfer'
require_relative 'we_transfer_client'
require 'dotenv'
Dotenv.load

client = WeTransferClient.new(api_key: ENV.fetch('WT_API_KEY'), logger: Logger.new($stderr))
transfer = client.create_transfer(title: 'My amazing board', message: 'Hi there!') do |builder|
  builder.add_file(name: File.basename(__FILE__), io: File.open(__FILE__, 'rb'))
end

puts transfer.short_url