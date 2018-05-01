require 'webrick'
require 'securerandom'
include WEBrick

class ForbiddenServlet < HTTPServlet::AbstractServlet
  def do_GET(_req, res)
    res['Content-Type'] = 'application/json'
    res.status = 403
  end
  def do_POST(_req, res)
    res['Content-Type'] = 'application/json'
    res.status = 403
  end
end

class AuthServlet < HTTPServlet::AbstractServlet
  def do_POST(req, res)
    if req.header["x-api-key"].empty?
      res['Content-Type'] = 'application/json'
      res.status = 401
    else
      res['Content-Type'] = 'application/json'
      res.status = 200
      res.body = {status: 'success', token: SecureRandom.hex(4)}.to_json
    end
  end
end

class TransfersServlet < HTTPServlet::AbstractServlet
  def self.do_POST(req, res)
    content = JSON.parse(req.body)
    res['Content-Type'] = 'application/json'
    res.status = 200
    res.body = {shortened_url: "http://we.tl/s-#{SecureRandom.hex(5)}",
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

  def self.item_params(items:)
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
                      upload_url:"#{ENV.fetch('WT_API_URL')}/upload/#{SecureRandom.hex(9)}",
                      upload_id: SecureRandom.hex(9),
                      upload_expires_at: (Time.now + 5).to_i
                    }
    end
    return items_array
  end

  def self.totalsize_calc(items:)
    total_size = []
    items.each do |item|
      total_size << item['filesize']
    end
    total_size.sum
  end

  def self.multipart_calc(item:)
    parts = item['filesize'] / 6291456
    parts == 0 ? 1 : parts
  end
end

class UploadUrlServlet < HTTPServlet::AbstractServlet
  def self.do_GET(_req, res)
    part_number = res.request_uri.to_s.split('/').last
    res['Content-Type'] = 'application/json'
    res.status = 200
    res.body = {  upload_url: "#{ENV.fetch('WT_API_URL')}/upload/#{SecureRandom.hex(9)}",
                  part_number: part_number,
                  upload_id: SecureRandom.hex(9),
                  upload_expires_at: (Time.now + 5).to_i
                }.to_json
  end
end

class UploadPartServlet < HTTPServlet::AbstractServlet
  def self.do_PUT(_req, res)
    res['Content-Type'] = 'application/json'
    res.status = 200
  end
end

class TransferItemServlet < HTTPServlet::AbstractServlet
  # this servlet is used for add_items_to_transfer functionality
  def self.do_POST(req, res)
    content = JSON.parse(req.body)
    res['Content-Type'] = 'application/json'
    res.status = 200
    res.body = item_params(items: content["items"]).to_json
  end

  def self.item_params(items:)
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
                      upload_url:"#{ENV.fetch('WT_API_URL')}/upload/#{SecureRandom.hex(9)}",
                      upload_id: SecureRandom.hex(9),
                      upload_expires_at: (Time.now + 5).to_i
                    }
    end
    return items_array
  end
  def self.multipart_calc(item:)
    parts = item['filesize'] / 6291456
    parts == 0 ? 1 : parts
  end
end

class UploadServlet < HTTPServlet::AbstractServlet
  def do_PUT(req, res)
    res['Content-Type'] = 'application/json'
    res.status = 200
  end
end

class CompleteItemServlet < HTTPServlet::AbstractServlet
  def self.do_POST(_req, res)
    res['Content-Type'] = 'application/json'
    res.status = 202
    res.body = {ok: true, message: 'File is marked as complete.'}.to_json
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
    # upload_server = WEBrick::HTTPServer.new(server_name:'wetransfer-test.com', Port: 9002)
    @server.mount('/forbidden',     ForbiddenServlet)
    @server.mount('/v1/authorize',  AuthServlet)
    # This needs to look nicer
    @server.mount_proc('/v1/transfers') do |req, res|
      if req.path =~ /^(?=.*\bv1\b)(?=.*\btransfers\b)(?=.*\bitems\b).+/
        TransferItemServlet.do_POST(req, res)
      else
        TransfersServlet.do_POST(req, res)
      end
    end
    @server.mount_proc('/v1/files/') do |req, res|
      if req.request_method == "PUT"
        UploadPartServlet.do_PUT(req, res)
      elsif req.request_method == "GET"
        UploadUrlServlet.do_GET(req, res)
      else
        CompleteItemServlet.do_POST(req,res)
      end
    end
    @server.mount('/upload', UploadServlet)

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
