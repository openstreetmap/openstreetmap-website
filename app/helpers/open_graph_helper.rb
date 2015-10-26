module OpenGraphHelper
  def opengraph_tags(title = nil)
    tags = {
      "og:site_name" => t("layouts.project_name.title"),
      "og:title" => [t("layouts.project_name.title"), title].compact.join(" | "),
      "og:type" => "website",
      "og:image" => image_path("osm_logo.svg", :host => SERVER_URL),
      "og:image:width" => "200",
      "og:image:height" => "200"
    }

    tags.map do |property, content|
      tag(:meta, :property => property, :content => content)
    end.join("").html_safe
  end
end
