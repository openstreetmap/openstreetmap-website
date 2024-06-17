module OpenGraphHelper
  require "addressable/uri"

  def opengraph_tags(title = nil, og_image = nil)
    tags = {
      "og:site_name" => t("layouts.project_name.title"),
      "og:title" => title || t("layouts.project_name.title"),
      "og:type" => "website",
      "og:image" => og_image_url(og_image),
      "og:url" => url_for(:only_path => false),
      "og:description" => t("layouts.intro_text")
    }

    safe_join(tags.map do |property, content|
      tag.meta(:property => property, :content => content)
    end, "\n")
  end

  private

  def og_image_url(og_image)
    begin
      return Addressable::URI.join(root_url, og_image).normalize if og_image
    rescue Addressable::URI::InvalidURIError
      # return default image
    end
    image_url("osm_logo_256.png")
  end
end
