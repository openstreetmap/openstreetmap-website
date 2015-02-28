module Auth
  PROVIDERS = { "None" => "", "OpenID" => "openid" }
  PROVIDERS["Google"] = "google" if defined?(GOOGLE_AUTH_ID)
end
