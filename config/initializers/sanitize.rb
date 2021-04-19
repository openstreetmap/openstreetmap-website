Sanitize::Config::OSM = Sanitize::Config.merge(
  Sanitize::Config::RELAXED,
  :elements => Sanitize::Config::RELAXED[:elements] - %w[div style],
  :add_attributes => { "a" => { "rel" => "nofollow noopener noreferrer" } },
  :remove_contents => %w[script style],
  :transformers => lambda do |env|
    env[:node].remove_class
    env[:node].kwattr_remove("style", nil)
    env[:node].add_class("table table-sm w-auto") if env[:node_name] == "table"
  end
)
