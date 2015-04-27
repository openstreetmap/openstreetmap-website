module Auth
  PROVIDERS = { "None" => "", "OpenID" => "openid" }
  PROVIDERS["Google"] = "google" if defined?(GOOGLE_AUTH_ID)
  PROVIDERS["Facebook"] = "facebook" if defined?(FACEBOOK_AUTH_ID)
  PROVIDERS["Windows Live"] = "windowslive" if defined?(WINDOWSLIVE_AUTH_ID)
end
