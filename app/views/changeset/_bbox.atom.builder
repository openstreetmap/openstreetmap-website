xml.a(bbox.to_s, :href => url_for(:controller => "site", :action => "index", :minlon => bbox.min_lon, :minlat => bbox.min_lat, :maxlon => bbox.max_lon, :maxlat => bbox.max_lat, :box => "yes"))
