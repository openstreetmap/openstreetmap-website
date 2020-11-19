Sanitize::Config::OSM = Sanitize::Config::RELAXED.dup

Sanitize::Config::OSM[:elements] -= %w[div style]
Sanitize::Config::OSM[:add_attributes] = { "a" => { "rel" => "nofollow noopener noreferrer" } }
Sanitize::Config::OSM[:remove_contents] = %w[script style]
Sanitize::Config::OSM[:transformers] = lambda do |env|
  env[:node].add_class("table table-sm w-auto") if env[:node_name] == "table"
end
