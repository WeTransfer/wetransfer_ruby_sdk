# require 'vcr'

module WtVCR
  SENSITIVE = "<SENSITIVE>".freeze

  def self.laserdisc(name = nil, options = {}, &block)
    # filename, line = caller[0].split(':')
    # cassette_name = name || filename.split("/spec").last + line
    # VCR.use_cassette(cassette_name, options, &block)
  end
end

# VCR.configure do |config|
#   config.cassette_library_dir = "spec/cassettes"
#   config.hook_into :webmock
#   config.filter_sensitive_data(WtVCR::SENSITIVE) { ENV.fetch('WT_API_KEY') }
#   config.filter_sensitive_data(WtVCR::SENSITIVE) do |interaction|
#     interaction.request.headers['Authorization']&.first
#   end
#   config.filter_sensitive_data(WtVCR::SENSITIVE) do |interaction|
#     interaction.request.headers['X-Amz-Id-2']&.first
#   end
#   config.filter_sensitive_data(WtVCR::SENSITIVE) do |interaction|
#     response_body = interaction.response.body
#     begin
#       JSON.parse(response_body)["token"] unless response_body.empty?
#     rescue TypeError
#       # no filtering of sensitive tokens necessary, no breaking of the test either
#     end
#   end
# end
