Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "gpx" => "GPX",
    "id" => "ID",
    "osm" => "OSM",
    "utf8" => "UTF8"
  )
end
