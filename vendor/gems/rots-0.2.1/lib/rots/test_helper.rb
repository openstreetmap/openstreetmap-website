require "openid/consumer"
require "openid/consumer/checkid_request.rb"
require "net/http"

module Rots::TestHelper
  
  def openid_request(openid_request_uri)
    openid_response = Net::HTTP.get_response(URI.parse(openid_request_uri))
    openid_response_uri = URI(openid_response['Location'])
    openid_response_qs = Rack::Utils.parse_query(openid_response_uri.query)
    
    { :url => openid_response_uri.to_s,
      :query_params => openid_response_qs }
  end
  
end