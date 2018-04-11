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
    @server.mount('/forbidden', ForbiddenServlet)
    @server.mount('/v1/authorize', AuthServlet)
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
