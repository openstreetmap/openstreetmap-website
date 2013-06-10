require 'oauth'

class ClientApplication < ActiveRecord::Base
  belongs_to :user
  has_many :tokens, :class_name => "OauthToken", :dependent => :delete_all
  has_many :access_tokens
  has_many :oauth2_verifiers
  has_many :oauth_tokens

  validates_presence_of :name, :url, :key, :secret
  validates_uniqueness_of :key
  validates_format_of :url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i
  validates_format_of :support_url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank=>true
  validates_format_of :callback_url, :with => /\A[a-z][a-z0-9.+-]*:\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank=>true

  attr_accessible :name, :url, :support_url, :callback_url,
                  :allow_read_prefs, :allow_write_prefs,
                  :allow_write_diary, :allow_write_api,
                  :allow_read_gpx, :allow_write_gpx,
                  :allow_write_notes

  before_validation :generate_keys, :on => :create

  attr_accessor :token_callback_url
  
  def self.find_token(token_key)
    token = OauthToken.find_by_token(token_key, :include => :client_application)
    if token && token.authorized?
      token
    else
      nil
    end
  end

  def self.verify_request(request, options = {}, &block)
    begin
      signature = OAuth::Signature.build(request, options, &block)
      return false unless OauthNonce.remember(signature.request.nonce, signature.request.timestamp)
      value = signature.verify
      value
    rescue OAuth::Signature::UnknownSignatureMethod => e
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
    
  def create_request_token(params={})
    params = { :client_application => self, :callback_url => self.token_callback_url }
    permissions.each do |p|
      params[p] = true
    end
    RequestToken.create(params, :without_protection => true)
  end

  def access_token_for_user(user)
    unless token = access_tokens.valid.where(:user_id => user).first
      params = { :user => user }

      permissions.each do |p|
        params[p] = true
      end

      token = access_tokens.create(params, :without_protection => true)
    end
    
    token
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
                 :allow_write_api, :allow_read_gpx, :allow_write_gpx,
                 :allow_write_notes]

  def generate_keys
    self.key = OAuth::Helper.generate_key(40)[0,40]
    self.secret = OAuth::Helper.generate_key(40)[0,40]
  end
end
