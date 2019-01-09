Sanitize::Config::OSM = Sanitize::Config::RELAXED.dup

Sanitize::Config::OSM[:elements] -= %w[div style]
Sanitize::Config::OSM[:add_attributes] = { "a" => { "rel" => "nofollow noopener noreferer" } }
Sanitize::Config::OSM[:remove_contents] = %w[script style]
