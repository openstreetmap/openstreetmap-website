module BannerHelper

  def all_banners()
    {
      :sotmus2016 => {
        :id => 'sotmus2016',
        :alt => 'State of the Map US 2016',
        :link => 'http://stateofthemap.us/',
        :img => 'banners/sotmus-2016.jpg',
        :enddate => '2016-jul-23'
      },
      :sotm2016 => {
        :id => 'sotm2016',
        :alt => 'State of the Map 2016',
        :link => 'http://2016.stateofthemap.org/',
        :img => 'banners/sotm-2016.jpg',
        :enddate => '2016-sep-23'
      }
    }
  end

  def active_banners()
    all_banners().reject do |k,v|
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
