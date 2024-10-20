module OpenGraphHelper
  require "addressable/uri"

  def opengraph_tags(title, properties)
    tags = {
      "og:site_name" => t("layouts.project_name.title"),
      "og:title" => properties["og:title"] || title || t("layouts.project_name.title"),
      "og:type" => "website",
      "og:url" => url_for(:only_path => false),
      "og:description" => properties["og:description"] || t("layouts.intro_text")
    }.merge(
      opengraph_image_properties(properties)
    ).merge(
      properties.slice("article:published_time")
    )

    safe_join(tags.map do |property, content|
      tag.meta(:property => property, :content => content)
    end, "\n")
  end

  private

  def opengraph_image_properties(properties)
    begin
      if properties["og:image"]
        image_properties = {}
        image_properties["og:image"] = Addressable::URI.join(root_url, properties["og:image"]).normalize
        image_properties["og:image:alt"] = properties["og:image:alt"] if properties["og:image:alt"]
        return image_properties
      end
    rescue Addressable::URI::InvalidURIError
      # return default image
    end
    {
      "og:image" => image_url("osm_logo_256.png"),
      "og:image:alt" => t("layouts.logo.alt_text")
    }
  end
end
