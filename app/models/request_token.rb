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
      params = { :user => user, :client_application => client_application }
      # copy the permissions from the authorised request token to the access token
      client_application.permissions.each { |p| 
        params[p] = read_attribute(p)
      }

      access_token = AccessToken.create(params)
      invalidate!
      access_token
    end
  end
end
