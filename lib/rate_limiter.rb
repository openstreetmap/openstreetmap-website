# frozen_string_literal: true

class RateLimiter
  class Empty
    def allow?(_)
      true
    end

    def update(_); end
  end

  class Memcache
    def initialize(cache, interval, limit, max_burst)
      @cache = cache
      @requests_per_second = limit.to_f / interval
      @burst_limit = max_burst
    end

    def allow?(key)
      last_update, requests = @cache.get(key)

      if last_update
        elapsed = Time.now.to_i - last_update

        requests -= elapsed * @requests_per_second
      else
        requests = 0.0
      end

      requests < @burst_limit
    end

    def update(key)
      now = Time.now.to_i

      last_update, requests = @cache.get(key)

      if last_update
        elapsed = now - last_update

        requests -= elapsed * @requests_per_second
        requests += 1.0
      else
        requests = 1.0
      end

      @cache.set(key, [now, [requests, 1.0].max])
    end
  end

  def self.signup_email_limiter
    @signup_email_limiter ||=
      if Settings.memcache_servers && Settings.signup_email_per_day && Settings.signup_email_max_burst
        Memcache.new(
          Dalli::Client.new(
            Settings.memcache_servers,
            :protocol => :meta,
            :namespace => "rails:signup:email"
          ),
          86400,
          Settings.signup_email_per_day,
          Settings.signup_email_max_burst
        )
      else
        Empty.new
      end
  end

  def self.signup_ip_limiter
    @signup_ip_limiter ||=
      if Settings.memcache_servers && Settings.signup_ip_per_day && Settings.signup_ip_max_burst
        Memcache.new(
          Dalli::Client.new(
            Settings.memcache_servers,
            :protocol => :meta,
            :namespace => "rails:signup:ip"
          ),
          86400,
          Settings.signup_ip_per_day,
          Settings.signup_ip_max_burst
        )
      else
        Empty.new
      end
  end
end
