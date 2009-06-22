gem 'oauth', '>=0.2.1'
require 'oauth/signature/hmac/sha1'
require 'oauth/request_proxy/action_controller_request'
require 'oauth/server'
require 'oauth/rails/controller_methods'
ActionController::Base.send :include, OAuth::Rails::ControllerMethods
