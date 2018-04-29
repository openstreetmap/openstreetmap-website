ENV.fetch("TRUSTED_IPS", "").split.each do |ip|
  BetterErrors::Middleware.allow_ip! ip
end
