attrs = {
  "minlat" => format("%<lat>.7f", :lat => bounds.min_lat),
  "minlon" => format("%<lon>.7f", :lon => bounds.min_lon),
  "maxlat" => format("%<lat>.7f", :lat => bounds.max_lat),
  "maxlon" => format("%<lon>.7f", :lon => bounds.max_lon)
}

xml.bounds(attrs)
