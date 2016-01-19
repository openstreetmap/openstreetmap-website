module Auth
  PROVIDERS = { "None" => "", "OpenID" => "openid" }.tap do |providers|
    providers["Google"] = "google" if defined?(GOOGLE_AUTH_ID)
    providers["Facebook"] = "facebook" if defined?(FACEBOOK_AUTH_ID)
    providers["Windows Live"] = "windowslive" if defined?(WINDOWSLIVE_AUTH_ID)
  end.freeze
end
