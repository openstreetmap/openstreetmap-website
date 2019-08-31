module Auth
  PROVIDERS = { "None" => "", "OpenID" => "openid" }.tap do |providers|
    providers["Google"] = "google" if Settings.key?(:google_auth_id)
    providers["Facebook"] = "facebook" if Settings.key?(:facebook_auth_id)
    providers["Windows Live"] = "windowslive" if Settings.key?(:windowslive_auth_id)
    providers["GitHub"] = "github" if Settings.key?(:github_auth_id)
    providers["Wikipedia"] = "wikipedia" if Settings.key?(:wikipedia_auth_id)
  end.freeze
end
