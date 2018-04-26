require 'webrick'
require 'securerandom'
include WEBrick

class ForbiddenServlet < HTTPServlet::AbstractServlet
  def do_GET(_req, res)
    res['Content-Type'] = 'text/plain'
    res.status = 403
  end
end

class AuthServlet < HTTPServlet::AbstractServlet
  def do_POST(_req, res)
    res['Content-Type'] = 'application/json'
    res.status = 200
    res.body = {status: 'success', token: SecureRandom.hex(4)}.to_json
  end
end

class TransfersServlet < HTTPServlet::AbstractServlet
  def do_POST(_req, res)
    content = JSON.parse(_req.body)
    res['Content-Type'] = 'application/json'
    res.status = 200
    res.body = {shortened_url: "https://we.tl/s-#{SecureRandom.hex(5)}",
                id: SecureRandom.hex(9),
                name: content["name"],
                description: content["description"],
                size: totalsize_calc(items: content["items"]),
                total_items: content["items"].count,
                version_identifier: nil,
                state: 'uploading',
                items: item_params(items: content["items"])}.to_json
  end

  private

  def item_params(items:)
    items_array = []
    items.each do |item|
      items_array << {id: SecureRandom.hex(9),
                      local_identifier: item['filename'][0..36],
                      name: item['filename'],
                      size: item['filesize'],
                      meta:{
                        multipart_parts: multipart_calc(item: item),
                        multipart_id: SecureRandom.hex(9),
                      },
                      upload_url:"https://wetransfer-eu-test.s3.com/#{SecureRandom.hex(9)}",
                      upload_id: SecureRandom.hex(9),
                      upload_expires_at: (Time.now + 5).to_i
                    }
    end
    return items_array
  end

  def totalsize_calc(items:)
    total_size = []
    items.each do |item|
      total_size << item['filesize']
    end
    total_size.sum
  end

  def multipart_calc(item:)
    parts = item['filesize'] / 6291456
    parts == 0 ? 1 : parts
  end
end

class UploadUrlServlet < HTTPServlet::AbstractServlet
  def self.do_GET(_req, res)
    part_number = res.request_uri.to_s.split('/').last
    res['Content-Type'] = 'application/json'
    res.status = 200
    res.body = {  upload_url: "https://wetransfer-eu-test.s3.com/#{SecureRandom.hex(9)}",
                  part_number: part_number,
                  upload_id: SecureRandom.hex(9),
                  upload_expires_at: (Time.now + 5).to_i
                }
  end
end

class UploadPartServlet < HTTPServlet::AbstractServlet
  def self.do_PUT(_req, res)
    res['Content-Type'] = 'application/json'
    res.status = 200
  end
end


class TestServer
  def self.start(log_file = nil, port = 9001)
    new(log_file, port).start
  end

  def initialize(log_file = nil, port = 9001)
    log_file ||= StringIO.new
    log = WEBrick::Log.new(log_file)

    options = {
      Port: port,
      Logger: log,
      AccessLog: [
        [log, WEBrick::AccessLog::COMMON_LOG_FORMAT],
        [log, WEBrick::AccessLog::REFERER_LOG_FORMAT]
      ],
      DocumentRoot: File.expand_path(__dir__),
    }

    @server = WEBrick::HTTPServer.new(options)
    @server.mount('/forbidden',     ForbiddenServlet)
    @server.mount('/v1/authorize',  AuthServlet)
    @server.mount('/v1/transfers',  TransfersServlet)
    @server.mount_proc('/v1/files/') do |req, res|
      binding.pry
      if req.path =~ /^(?=.*\bv1\b)(?=.*\bfiles\b)(?=.*\buploads\b)(?=.*\bcomplete\b).+/
        UploadPartServlet.do_PUT(req, res)
      else
        UploadUrlServlet.do_GET(req, res)
      end
    end
    # @server.mount('/v1/files/',     UploadPartServlet)
  end

  def start
    trap('INT') {
      begin
        @server.shutdown unless @server.nil?
      rescue Object => e
        warn "Error #{__FILE__}:#{__LINE__}\n#{e.message}"
      end
    }

    @thread = Thread.new { @server.start }
    Thread.pass
    self
  end

  def join
    @thread.join if defined? @thread and @thread
    self
  end
end
