class OauthToken < ActiveRecord::Base
  belongs_to :client_application
  belongs_to :user

  scope :authorized, where("authorized_at IS NOT NULL and invalidated_at IS NULL")

  validates_uniqueness_of :token
  validates_presence_of :client_application, :token

  before_validation :generate_keys, :on => :create
  
  def invalidated?
    invalidated_at != nil
  end
  
  def invalidate!
    update_attributes(:invalidated_at => Time.now)
  end
  
  def authorized?
    authorized_at != nil && !invalidated?
  end
  
  def to_query
    "oauth_token=#{token}&oauth_token_secret=#{secret}"
  end
    
protected
  
  def generate_keys
    self.token = OAuth::Helper.generate_key(40)[0,40]
    self.secret = OAuth::Helper.generate_key(40)[0,40]
  end
end
