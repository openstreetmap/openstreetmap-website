class Oauth2Verifier < OauthToken
  validates :user, :presence => true, :associated => true

  attr_accessor :state

  def exchange!(_params = {})
    OauthToken.transaction do
      token = Oauth2Token.create! :user => user, :client_application => client_application, :scope => scope
      invalidate!
      token
    end
  end

  def code
    token
  end

  def redirect_url
    callback_url
  end

  def to_query
    q = "code=#{token}"
    q << "&state=#{URI.escape(state)}" if @state
    q
  end

  protected

  def generate_keys
    self.token = OAuth::Helper.generate_key(20)[0, 20]
    self.expires_at = 10.minutes.from_now
    self.authorized_at = Time.now
  end
end
