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
      logger.info("£££ In exchange!")
      params = { :user => user, :client_application => client_application }
      # copy the permissions from the authorised request token to the access token
      client_application.permissions.each { |p| 
        logger.info("£££ copying permission #{p} = #{read_attribute(p).inspect}")
        params[p] = read_attribute(p)
      }

      access_token = AccessToken.create(params)
      invalidate!
      access_token
    end
  end
end
