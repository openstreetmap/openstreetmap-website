module Auth
  @providers = []
  @providers << "google" if Settings.key?(:google_auth_id)
  @providers << "facebook" if Settings.key?(:facebook_auth_id)
  @providers << "microsoft" if Settings.key?(:microsoft_auth_id)
  @providers << "github" if Settings.key?(:github_auth_id)
  @providers << "wikipedia" if Settings.key?(:wikipedia_auth_id)
  @providers << "openstreetmap" if Settings.key?(:openstreetmap_auth_id)

  @providers.freeze

  def self.providers
    @providers
  end
end
