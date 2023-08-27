require "rate_limiter"

SIGNUP_IP_LIMITER = if Settings.memcache_servers && Settings.signup_ip_per_day && Settings.signup_ip_max_burst
                      RateLimiter.new(
                        Dalli::Client.new(Settings.memcache_servers, :namespace => "rails:signup:ip"),
                        86400, Settings.signup_ip_per_day, Settings.signup_ip_max_burst
                      )
                    end

SIGNUP_EMAIL_LIMITER = if Settings.memcache_servers && Settings.signup_email_per_day && Settings.signup_email_max_burst
                         RateLimiter.new(
                           Dalli::Client.new(Settings.memcache_servers, :namespace => "rails:signup:email"),
                           86400, Settings.signup_email_per_day, Settings.signup_email_max_burst
                         )
                       end
