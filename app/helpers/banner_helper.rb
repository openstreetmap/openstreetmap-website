module BannerHelper

  def active_banners()
    BANNERS.reject do |k,v|
      enddate = v[:enddate]
      parsed = (enddate and Date.parse enddate rescue nil)
      parsed.is_a?(Date) and parsed.past?
    end
  end

  # returns the least recently seen banner that is not hidden
  def next_banner()
    banners = active_banners()
    bannerKey = nil
    cookieKey = nil
    queuePos = 9999

    banners.each do |k, v|
      ckey = cookie_id(v[:id]).to_sym
      cval = cookies[ckey] || 0
      next if cval == 'hide'

      # rotate all banner queue positions
      index = cval.to_i
      if index > 0
        cookies[ckey] = index - 1
      end

      # pick banner with mininum queue position
      if index <= queuePos
        bannerKey = k
        cookieKey = ckey
        queuePos = index
      end
    end

    unless bannerKey.nil?
      cookies[cookieKey] = banners.length   # bump to end of queue
      banners[bannerKey]
    end
  end

  def cookie_id(key)
    "_osm_banner_#{key}"
  end

end
