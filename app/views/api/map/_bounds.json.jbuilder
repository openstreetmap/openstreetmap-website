json.bounds do
  json.minlat GeoRecord::Coord.new(@bounds.min_lat)
  json.minlon GeoRecord::Coord.new(@bounds.min_lon)
  json.maxlat GeoRecord::Coord.new(@bounds.max_lat)
  json.maxlon GeoRecord::Coord.new(@bounds.max_lon)
end
