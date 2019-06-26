attrs = {
  "minlat" => format("%.7f", bounds.min_lat),
  "minlon" => format("%.7f", bounds.min_lon),
  "maxlat" => format("%.7f", bounds.max_lat),
  "maxlon" => format("%.7f", bounds.max_lon)
}

xml.bounds(attrs)
