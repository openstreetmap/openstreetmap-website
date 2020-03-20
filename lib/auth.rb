module Auth
  PROVIDERS = {
    I18n.t("auth.providers.none") => "",
    I18n.t("auth.providers.openid") => "openid"
  }.tap do |providers|
    providers[I18n.t("auth.providers.google")] = "google" if Settings.key?(:google_auth_id)
    providers[I18n.t("auth.providers.facebook")] = "facebook" if Settings.key?(:facebook_auth_id)
    providers[I18n.t("auth.providers.windowslive")] = "windowslive" if Settings.key?(:windowslive_auth_id)
    providers[I18n.t("auth.providers.github")] = "github" if Settings.key?(:github_auth_id)
    providers[I18n.t("auth.providers.wikipedia")] = "wikipedia" if Settings.key?(:wikipedia_auth_id)
  end.freeze
end
