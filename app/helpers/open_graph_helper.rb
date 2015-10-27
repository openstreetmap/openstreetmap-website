module OpenGraphHelper
  def opengraph_tags(title = nil)
    tags = {
      "og:site_name" => t("layouts.project_name.title"),
      "og:title" => [t("layouts.project_name.title"), title].compact.join(" | "),
      "og:type" => "website",
      "og:image" => image_path("osm_logo_256.png", :host => SERVER_URL, :protocol => "http"),
      "og:image:secure_url" => image_path("osm_logo_256.png", :host => SERVER_URL, :protocol => "https"),
      "og:url" => url_for(:host => SERVER_URL),
      "og:description" => t("layouts.intro_text")
    }

    tags.map do |property, content|
      tag(:meta, :property => property, :content => content)
    end.join("").html_safe
  end
end
