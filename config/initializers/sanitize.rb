Sanitize::Config::OSM = Sanitize::Config.merge(
  Sanitize::Config::RELAXED,
  :elements => Sanitize::Config::RELAXED[:elements] - %w[div style],
  :remove_contents => %w[script style],
  :transformers => lambda do |env|
    env[:node].remove_class
    env[:node].kwattr_remove("style", nil)
    env[:node].add_class("table table-sm w-auto") if env[:node_name] == "table"

    if env[:node_name] == "a"
      rel = env[:node]["rel"] || ""

      env[:node]["rel"] = rel.split.select { |r| r == "me" }.append("nofollow", "noopener", "noreferrer").sort.join(" ")
    end
  end
)
