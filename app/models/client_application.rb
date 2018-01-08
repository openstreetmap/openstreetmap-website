# == Schema Information
#
# Table name: client_applications
#
#  id                :integer          not null, primary key
#  name              :string
#  url               :string
#  support_url       :string
#  callback_url      :string
#  key               :string(50)
#  secret            :string(50)
#  user_id           :integer
#  created_at        :datetime
#  updated_at        :datetime
#  allow_read_prefs  :boolean          default(FALSE), not null
#  allow_write_prefs :boolean          default(FALSE), not null
#  allow_write_diary :boolean          default(FALSE), not null
#  allow_write_api   :boolean          default(FALSE), not null
#  allow_read_gpx    :boolean          default(FALSE), not null
#  allow_write_gpx   :boolean          default(FALSE), not null
#  allow_write_notes :boolean          default(FALSE), not null
#
# Indexes
#
#  index_client_applications_on_key      (key) UNIQUE
#  index_client_applications_on_user_id  (user_id)
#
# Foreign Keys
#
#  client_applications_user_id_fkey  (user_id => users.id)
#

require "oauth"

class ClientApplication < ActiveRecord::Base
  belongs_to :user
  has_many :tokens, :class_name => "OauthToken", :dependent => :delete_all
  has_many :access_tokens
  has_many :oauth2_verifiers
  has_many :oauth_tokens

  validates :key, :presence => true, :uniqueness => true
  validates :name, :url, :secret, :presence => true
  validates :url, :format => %r{\Ahttp(s?)://(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(/|/([\w#!:.?+=&%@!\-/]))?}i
  validates :support_url, :allow_blank => true, :format => %r{\Ahttp(s?)://(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(/|/([\w#!:.?+=&%@!\-/]))?}i
  validates :callback_url, :allow_blank => true, :format => %r{\A[a-z][a-z0-9.+-]*://(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(/|/([\w#!:.?+=&%@!\-/]))?}i

  before_validation :generate_keys, :on => :create

  attr_accessor :token_callback_url

  def self.find_token(token_key)
    token = OauthToken.includes(:client_application).find_by(:token => token_key)
    token if token && token.authorized?
  end

  def self.verify_request(request, options = {}, &block)
    signature = OAuth::Signature.build(request, options, &block)
    return false unless OauthNonce.remember(signature.request.nonce, signature.request.timestamp)
    value = signature.verify
    value
  rescue OAuth::Signature::UnknownSignatureMethod
    false
  end

  def self.all_permissions
    PERMISSIONS
  end

  def oauth_server
    @oauth_server ||= OAuth::Server.new("https://" + SERVER_URL)
  end

  def credentials
    @oauth_client ||= OAuth::Consumer.new(key, secret)
  end

  def create_request_token(_params = {})
    params = { :client_application => self, :callback_url => token_callback_url }
    permissions.each do |p|
      params[p] = true
    end
    RequestToken.create(params)
  end

  def access_token_for_user(user)
    unless token = access_tokens.valid.find_by(:user_id => user)
      params = { :user => user }

      permissions.each do |p|
        params[p] = true
      end

      token = access_tokens.create(params)
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
  PERMISSIONS = [:allow_read_prefs, :allow_write_prefs, :allow_write_diary, :allow_write_api, :allow_read_gpx, :allow_write_gpx, :allow_write_notes].freeze

  def generate_keys
    self.key = OAuth::Helper.generate_key(40)[0, 40]
    self.secret = OAuth::Helper.generate_key(40)[0, 40]
  end
end
