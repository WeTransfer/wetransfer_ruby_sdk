module Faraday::Connection::Debugger
  def get(*args, &block)
    puts " [Debug]: #{caller[0][/`.*'/][1..-2]} called #{__callee__} for endpoint #{args[0]}"
    super
  end

  def put(*args, &block)
    puts " [Debug]: #{caller[0][/`.*'/][1..-2]} called #{__callee__} for endpoint #{args[0]}"
    super
  end

  def post(*args, &block)
    puts " [Debug]: #{caller[0][/`.*'/][1..-2]} called #{__callee__} for endpoint #{args[0]}"
    super
  end
end

class Faraday::Connection
  # prepend Faraday::Connection::Debugger
end
