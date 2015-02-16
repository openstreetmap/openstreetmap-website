##
# Load required libraries
require 'soap/wsdlDriver'

##
# Monkey patch WSDL parser to stop it moaning
module WSDL
  class Parser
    def warn(_msg)
    end
  end
end

##
# Provide interface to Quova geolocation service
module Quova
  ##
  # Access details for WSDL description
  WSDL_URL = "https://webservices.quova.com/OnDemand/GeoPoint/v1/default.asmx?WSDL"
  WSDL_USER = QUOVA_USERNAME
  WSDL_PASS = QUOVA_PASSWORD

  ##
  # Status codes
  Success = 0
  IPV6NoSupport = 1
  InvalidCredentials = 2
  NotMapped = 3
  InvalidIPFormat = 4
  IPAddressNull = 5
  AccessDenied = 6
  QueryLimit = 7
  OutOfService = 10

  ##
  # Create SOAP endpoint
  @@soap = SOAP::WSDLDriverFactory.new(WSDL_URL).create_rpc_driver
  @@soap.options["protocol.http.basic_auth"] << [WSDL_URL, WSDL_USER, WSDL_PASS]

  ##
  # Accessor for SOAP endpoint
  def self.soap
    @@soap
  end

  ##
  # Class representing geolocation details for an IP address
  class IpInfo
    def initialize(ip_address)
      @ipinfo = Quova.soap.GetIpInfo(:ipAddress => ip_address)
    end

    def status
      @ipinfo["GetIpInfoResult"]["Response"]["Status"].to_i
    end

    def country_code
      @ipinfo["GetIpInfoResult"]["Location"]["Country"]["Name"]
    end

    def country_confidence
      @ipinfo["GetIpInfoResult"]["Location"]["Country"]["Confidence"]
    end
  end
end
