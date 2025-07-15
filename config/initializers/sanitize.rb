Sanitize::Config::OSM = Sanitize::Config.merge(
  Sanitize::Config::RELAXED,
  :elements => Sanitize::Config::RELAXED[:elements] - %w[div style],
  :remove_contents => %w[script style],
  :attributes => Sanitize::Config.merge(
    Sanitize::Config::RELAXED[:attributes],
    "img" => Sanitize::Config::RELAXED[:attributes]["img"] + ["loading"]
  ),
  :transformers => lambda do |env|
    style = env[:node]["style"] || ""

    env[:node].remove_class
    env[:node].remove_attribute("style")

    env[:node].add_class("table table-sm w-auto") if env[:node_name] == "table"

    case style
    when /\btext-align:\s+left\b/
      env[:node].add_class("text-start")
    when /\btext-align:\s+center\b/
      env[:node].add_class("text-center")
    when /\btext-align:\s+right\b/
      env[:node].add_class("text-end")
    end

    if env[:node_name] == "a"
      rel = env[:node]["rel"] || ""

      env[:node]["rel"] = rel.split.select { |r| r == "me" }.append("nofollow", "noopener", "noreferrer").sort.join(" ")
    end

    env[:node]["loading"] = "lazy" if env[:node_name] == "img"
  end
)
