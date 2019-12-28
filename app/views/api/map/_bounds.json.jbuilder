json.bounds do
  json.minlat format("%.7f", @bounds.min_lat)
  json.minlon format("%.7f", @bounds.min_lon)
  json.maxlat format("%.7f", @bounds.max_lat)
  json.maxlon format("%.7f", @bounds.max_lon)
end
