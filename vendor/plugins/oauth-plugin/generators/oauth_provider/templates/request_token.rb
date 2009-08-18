class RequestToken < OauthToken
  def authorize!(user)
    return false if authorized?
    self.user = user
    self.authorized_at = Time.now
    self.save
  end
  
  def exchange!
    return false unless authorized?
    RequestToken.transaction do
      access_token = AccessToken.create(:user => user, :client_application => client_application)
      invalidate!
      access_token
    end
  end
end