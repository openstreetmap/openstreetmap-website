class RateLimiter
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
