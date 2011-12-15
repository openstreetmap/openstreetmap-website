$:.unshift(File.dirname(__FILE__), '..', 'lib')
require "rubygems"
require "spec"
require "rack"
require "rots"

module Rots::RequestHelper
  
  def checkid_setup(request, params={}, with_associate=true)
    assoc_handle = make_association(request) if with_associate
    send_checkid(request, :setup, params, assoc_handle)
  end
  
  def checkid_immediate(request, params={}, with_associate=true)
    assoc_handle = make_association(request) if with_associate
    send_checkid(request, :immediate, params, assoc_handle)
  end
  
  def openid_params(response)
    uri = URI(response.headers['Location'])
    Rack::Utils.parse_query(uri.query)
  end
  
  protected
  
  def send_checkid(request, mode, params={}, assoc_handle = nil)
    params = self.send(:"checkid_#{mode}_params", params)
    params.merge('openid.assoc_handle' => assoc_handle) if assoc_handle
    qs = "/?" + Rack::Utils.build_query(params)
    request.get(qs)
  end

  def make_association(request)
    associate_qs = Rack::Utils.build_query(associate_params)
    response = request.post('/', :input => associate_qs)
    parse_assoc_handle_from(response)
  end
  
  def parse_assoc_handle_from(response)
    response.body.split("\n")[0].match(/^assoc_handle:(.*)$/).captures[0]
  end
  
  def checkid_setup_params(params = {})
    {
      "openid.ns" => "http://specs.openid.net/auth/2.0",
      "openid.mode" => "checkid_setup",
      "openid.claimed_id" => 'john.doe',
      "openid.identity" => 'john.doe',
      "openid.return_to" => "http://www.google.com"
      # need to specify the openid_handle by hand
    }.merge!(params)
  end
  
  def checkid_immediate_params(params = {})
    checkid_setup_params({'openid.mode' => 'checkid_immediate'}.merge!(params))
  end
  
  def associate_params
    {
      "openid.ns" => "http://specs.openid.net/auth/2.0",
      "openid.mode" => "associate",
      "openid.session_type" => "DH-SHA1",
      "openid.assoc_type" => "HMAC-SHA1",
      "openid.dh_consumer_public" =>
      "U672/RsDUNxAFFAXA+ShVh5LMD2CRdsoqdqhDCPUzfCNy2f44uTWuid/MZuGfJmiVA7QmxqM3GSb8EVq3SGK8eGEwwyzUtatqHidx72rfwAav5AUrZTnwSPQJyiCFrKNGmNhXdRJzcfzSkgaC3hVz2kpADzEevIExG6agns1sYY="
    }
  end
  
end

Spec::Runner.configure do |config|
  config.include Rots::RequestHelper
end