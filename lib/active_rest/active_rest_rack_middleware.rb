require 'rack/utils'
require 'uuid'

class ActiveRest::RequestInfo
  def initialize
    @info = {}
  end

  def get
    @info
  end

  def update(header, value)
    @info[header] = value
  end

  def clear
    @info = {}
  end
end

module ActiveRest
  REQUEST_INFO = ActiveRest::RequestInfo.new
end

class ActiveRest::RackMiddleware
  def initialize(app)
    @app = app
    @uuid = UUID.new
  end

  def call(env)
    req = Rack::Request.new(env)
    ActiveRest::REQUEST_INFO.update('Referer', req.url)
    ActiveRest::REQUEST_INFO.update('X-Request-ID', @uuid.generate)
    ActiveRest::REQUEST_INFO.update('X-Session-ID', (env['rack.session'] && env['rack.session']['session_id']) ? env['rack.session']['session_id'] : "")
    ActiveRest::REQUEST_INFO.update('X-User-ID', (env['rack.session'] && env['rack.session']['current_user_id']) ? env['rack.session']['current_user_id'] : "")

    result = @app.call(env)

    ActiveRest::REQUEST_INFO.clear
    result
  end
end
