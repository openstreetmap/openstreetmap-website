require 'rack/request'
require 'rack/response'
require 'rack/utils'
require 'openid'

class Rots::IdentityPageApp 
  
  def initialize(config, server_options)
    @server_options = server_options
    @config = config
  end
  
  def call(env)
    @request = Rack::Request.new(env)
    Rack::Response.new do |response|
      response.write <<-HERE
<html>
  <head>
  <link rel="openid2.provider" href="#{op_endpoint}" />
  <link rel="openid.server" href="#{op_endpoint}" />
  </head>
  <body>
    <h1>This is #{@config['identity']} identity page</h1>
  </body>
</html>
      HERE
    end.finish
  end
  
  def op_endpoint
    "http://%s:%d/server/%s" % [@request.host, 
                           @request.port, 
                           (@request.params['openid.success'] ? '?openid.success=true' : '')]
  end
  
end