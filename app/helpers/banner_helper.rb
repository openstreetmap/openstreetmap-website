module BannerHelper
  def active_banners
    BANNERS.reject do |_k, v|
      enddate = v[:enddate]
      begin
        parsed = enddate && Date.parse(enddate)
      rescue
        parsed = nil
      end
      parsed.is_a?(Date) && parsed.past?
    end
  end

  # returns the least recently seen banner that is not hidden
  def next_banner
    banners = active_banners
    banner_key = nil
    cookie_key = nil
    min_index = 9999

    banners.each do |k, v|
      ckey = cookie_id(v[:id]).to_sym
      cval = cookies[ckey] || 0
      next if cval == "hide"

      # rotate all banner queue positions
      index = cval.to_i
      cookies[ckey] = index - 1 if index > 0

      # pick banner with mininum queue position
      next if index > min_index

      banner_key = k
      cookie_key = ckey
      min_index = index
    end

    unless banner_key.nil?
      cookies[cookie_key] = banners.length # bump to end of queue
      banners[banner_key]
    end
  end

  def cookie_id(key)
    "_osm_banner_#{key}"
  end
end
