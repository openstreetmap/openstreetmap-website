module OpenGraphHelper
  require "addressable/uri"

  def opengraph_tags(title, og_image, og_image_alt)
    tags = {
      "og:site_name" => t("layouts.project_name.title"),
      "og:title" => title || t("layouts.project_name.title"),
      "og:type" => "website",
      "og:url" => url_for(:only_path => false),
      "og:description" => t("layouts.intro_text")
    }.merge(
      opengraph_image_properties(og_image, og_image_alt)
    )

    safe_join(tags.map do |property, content|
      tag.meta(:property => property, :content => content)
    end, "\n")
  end

  private

  def opengraph_image_properties(og_image, og_image_alt)
    begin
      if og_image
        properties = {}
        properties["og:image"] = Addressable::URI.join(root_url, og_image).normalize
        properties["og:image:alt"] = og_image_alt if og_image_alt
        return properties
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
