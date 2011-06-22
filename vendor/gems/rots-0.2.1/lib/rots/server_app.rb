require 'openid'
require 'openid/extension'
require 'openid/extensions/sreg'
require 'openid/store/filesystem'
require 'openid/util'
require 'rack/request'
require 'rack/utils'
require 'fileutils'


module Rots
  
  class ServerApp
    
    attr_accessor :request,:openid_request,
                  :response, :openid_response,
                  :server
    
    def initialize(config, server_options)
      @server_options = server_options
      @sreg_fields = config['sreg']
    end
    
    def call(env)
      on_openid_request(env) do
        if !is_checkid_request?
          @openid_response = @server.handle_request(@openid_request)
          reply_consumer
        elsif is_checkid_immediate?
          process_immediate_checkid_request
        else
          process_checkid_request
        end
      end
    end
    
    protected
    
    def on_openid_request(env)
      create_wrappers(env)
      if @openid_request.nil?
        [200, {'Content-Type' => 'text/html'}, 
          ["<html><body><h1>ROTS => This is an OpenID endpoint</h1></body></html>"] ]
      else
        yield
      end
    end
    
    def create_wrappers(env)
      @request = Rack::Request.new(env)
      @server  = OpenID::Server::Server.new(storage, op_endpoint)
      @openid_request = @server.decode_request(@request.params)
      @openid_sreg_request = OpenID::SReg::Request.from_openid_request(@openid_request) unless @openid_request.nil?
    end
    
    def is_checkid_request?
      @openid_request.is_a?(OpenID::Server::CheckIDRequest)
    end
    
    def is_checkid_immediate?
      @openid_request && @openid_request.immediate
    end
    
    def process_immediate_checkid_request
      # TODO: We should enable the user to configure
      # if she wants immediate request support or not
      url = OpenID::Util.append_args(@openid_request.return_to, 
        @request.params.merge('openid.mode' => 'setup_needed'))
      redirect(url)
    end
    
    def process_checkid_request
      if checkid_request_is_valid?
        return_successful_openid_response
      else
        return_cancel_openid_response
      end
    end
    
    def checkid_request_is_valid?
      @request.params['openid.success'] == 'true'
    end
    
    def return_successful_openid_response
      @openid_response = @openid_request.answer(true)
      process_sreg_extension
      # TODO: Add support for SREG extension
      @server.signatory.sign(@openid_response) if @openid_response.needs_signing
      reply_consumer
    end
    
    def process_sreg_extension
      return if @openid_sreg_request.nil?
      response = OpenID::SReg::Response.extract_response(@openid_sreg_request, @sreg_fields)
      @openid_response.add_extension(response)
    end
    
    def return_cancel_openid_response
      redirect(@openid_request.cancel_url)
    end
    
    def reply_consumer
      web_response = @server.encode_response(@openid_response)
      case web_response.code
      when OpenID::Server::HTTP_OK
        success(web_response.body)
      when OpenID::Server::HTTP_REDIRECT
        redirect(web_response.headers['location'])
      else
        bad_request
      end   
    end

    def redirect(uri)
      [ 303, {'Content-Length'=>'0', 'Content-Type'=>'text/plain',
        'Location' => uri},
        [] ]
    end

    def bad_request()
      [ 400, {'Content-Type'=>'text/plain', 'Content-Length'=>'0'},
        [] ]
    end
    
    def storage
      # create the folder if it doesn't exist
      FileUtils.mkdir_p(@server_options[:storage]) unless File.exist?(@server_options[:storage])
      OpenID::Store::Filesystem.new(@server_options[:storage])
    end
    
    def success(text="")
      Rack::Response.new(text).finish
    end
    
    def op_endpoint
      if @request.url =~ /(.*\?openid.success=true)/
        $1
      elsif @request.url =~ /([^?]*)/
        $1
      else
        nil
      end
    end

  end

end