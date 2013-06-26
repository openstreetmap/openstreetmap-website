class AccessToken < OauthToken
  belongs_to :user
  belongs_to :client_application

  scope :valid, -> { where(:invalidated_at => nil) }

  validates_presence_of :user, :secret

  before_create :set_authorized_at
  
protected 
  
  def set_authorized_at
    self.authorized_at = Time.now
  end
end
