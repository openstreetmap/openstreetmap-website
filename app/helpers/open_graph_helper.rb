module OpenGraphHelper
  def opengraph_tags(title, og_tags)
    og_tags = {} if og_tags.nil?
    default_og_tags = {
      "og:site_name" => t("layouts.project_name.title"),
      "og:title" => [title, t("layouts.project_name.title")].compact.join(" | "),
      "og:type" => "website",
      "og:image" => image_url("osm_logo_256.png", :protocol => "http"),
      "og:image:secure_url" => image_url("osm_logo_256.png", :protocol => "https"),
      "og:url" => url_for(:only_path => false),
      "og:description" => t("layouts.intro_text")
    }

    og_tags = og_tags.reverse_merge(default_og_tags)

    safe_join(og_tags.map do |property, content|
      tag.meta(:property => property, :content => content)
    end, "\n")
  end
end
