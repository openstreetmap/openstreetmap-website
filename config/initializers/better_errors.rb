# frozen_string_literal: true

ENV.fetch("TRUSTED_IPS", "").split.each do |ip|
  BetterErrors::Middleware.allow_ip! ip
end
