module MapLayers
  def self.full_definitions(layers_filename)
    YAML.load_file(Rails.root.join(layers_filename))
        .reject { |layer| layer["apiKeyId"] && !Settings[layer["apiKeyId"]] }
        .map do |layer|
          layer["name"] = I18n.t("site.index.map.base.#{layer['nameId']}")
          layer.delete "nameId"
          layer["attribution"] = make_attribution(layer["credit"])
          layer.delete "credit"
          if layer["apiKeyId"]
            layer["apikey"] = Settings[layer["apiKeyId"]]
            layer.delete "apiKeyId"
          end
          layer
        end
  end

  def self.embed_definitions(layers_filename)
    full_definitions(layers_filename)
      .select { |entry| entry["canEmbed"] }
      .to_h { |entry| [entry["layerId"], entry.slice("leafletOsmId", "leafletOsmDarkId", "apikey").compact] }
  end

  extend ActionView::Helpers::UrlHelper

  def self.make_attribution(credit)
    attribution = ""

    attribution += I18n.t("site.index.map.copyright_text",
                          :copyright_link => link_to(I18n.t("site.index.map.openstreetmap_contributors"), "/copyright"))

    attribution += credit["donate"] ? " &hearts; " : ". "
    attribution += make_credit(credit)
    attribution += ". "

    attribution += link_to(I18n.t("site.index.map.website_and_api_terms"),
                           "https://wiki.osmfoundation.org/wiki/Terms_of_Use")

    attribution
  end

  def self.make_credit(credit)
    children = credit["children"]&.transform_values { |child| make_credit(child) } || {}

    text = I18n.t("site.index.map.#{credit['id']}", **children.transform_keys(&:to_sym))

    return text unless credit["href"]

    link_to(text, credit["href"], :class => ("donate-attr" if credit["donate"]), :target => ("_blank" unless credit["donate"]))
  end
end
