module BannerHelper
  def active_banners
    BANNERS.reject do |_k, v|
      enddate = v[:enddate]
      begin
        parsed = enddate && Date.parse(enddate)
      rescue StandardError
        parsed = nil
      end
      !parsed.is_a?(Date) || (parsed.is_a?(Date) && parsed.past?)
    end
  end

  # returns the least recently seen banner that is not hidden
  def next_banner
    banners = active_banners
    banner_key = nil
    cookie_key = nil
    min_index = 9999
    min_date = Date.new(9999, 1, 1)

    banners.each do |k, v|
      ckey = banner_cookie(v[:id]).to_sym
      cval = cookies[ckey] || 0
      next if cval == "hide"

      # rotate all banner queue positions
      index = cval.to_i
      cookies[ckey] = index - 1 if index.positive?

      # pick banner with mininum queue position
      next if index > min_index

      # or if equal queue position, pick banner with soonest end date (i.e. next expiring)
      end_date = Date.parse(v[:enddate])
      next if index == min_index && end_date > min_date

      banner_key = k
      cookie_key = ckey
      min_index = index
      min_date = end_date
    end

    unless banner_key.nil?
      cookies[cookie_key] = banners.length # bump to end of queue
      banners[banner_key]
    end
  end

  def banner_cookie(key)
    "_osm_banner_#{key}"
  end
end
