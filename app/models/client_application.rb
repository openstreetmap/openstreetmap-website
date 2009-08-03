require 'oauth'
class ClientApplication < ActiveRecord::Base
  belongs_to :user
  has_many :tokens, :class_name => "OauthToken"
  validates_presence_of :name, :url, :key, :secret
  validates_uniqueness_of :key
  before_validation_on_create :generate_keys
  
  def self.verify_request(request, options = {}, &block)
    begin
      signature = OAuth::Signature.build(request, options, &block)
      logger.info "Signature Base String: #{signature.signature_base_string}"
      logger.info "Consumer: #{signature.send :consumer_key}"
      logger.info "Token: #{signature.send :token}"
      return false unless OauthNonce.remember(signature.request.nonce, signature.request.timestamp)
      value = signature.verify
      logger.info "Signature verification returned: #{value.to_s}"
      value
    rescue OAuth::Signature::UnknownSignatureMethod => e
      logger.info "ERROR"+e.to_s
      false
    end
  end
  
  def self.all_permissions
    PERMISSIONS
  end

  def oauth_server
    @oauth_server ||= OAuth::Server.new("http://" + SERVER_URL)
  end
  
  def credentials
    @oauth_client ||= OAuth::Consumer.new(key, secret)
  end
    
  def create_request_token
    RequestToken.create :client_application => self
  end

  # the permissions that this client would like from the user
  def permissions
    ClientApplication.all_permissions.select { |p| self[p] }
  end

protected
  
  # this is the set of permissions that the client can ask for. clients
  # have to say up-front what permissions they want and when users sign up they
  # can agree or not agree to each of them.
  PERMISSIONS = [:allow_read_prefs, :allow_write_prefs, :allow_write_diary,
                 :allow_write_api, :allow_read_gpx, :allow_write_gpx ]

  def generate_keys
    @oauth_client = oauth_server.generate_consumer_credentials
    self.key = @oauth_client.key
    self.secret = @oauth_client.secret
  end
end
