# frozen_string_literal: true

module MapLayers
  def self.full_definitions(layers_filename, legends: nil)
    legended_layers = YAML.load_file(Rails.root.join(legends)).keys if legends
    YAML.load_file(Rails.root.join(layers_filename))
        .filter_map do |layer|
          begin
            if layer["isVectorStyle"]
              layer["style"] = insert_api_key(layer, "styleUrl")
              layer["styleDark"] = insert_api_key(layer, "styleUrlDark") if layer["styleUrlDark"]
            else
              layer["style"] = style_from_tile_url(layer, "tileUrl")
              layer["styleDark"] = style_from_tile_url(layer, "tileUrlDark") if layer["tileUrlDark"]
              layer["url"] = insert_api_key(layer, "tileUrl")
              layer["urlDark"] = insert_api_key(layer, "tileUrlDark") if layer["tileUrlDark"]
              layer.delete "leafletOsmId"
              layer.delete "leafletOsmDarkId"
            end
          rescue StandardError => e
            Rails.logger.error "Error processing layer #{layer['layerId']}: #{e.message}"
            next
          end
          layer["hasLegend"] = true if legended_layers&.include?(layer["layerId"])
          layer.delete "apiKeyId"
          layer.delete "styleUrl"
          layer.delete "styleUrlDark"
          layer.delete "tileUrl"
          layer.delete "tileUrlDark"
          layer
        end
  end

  def self.embed_definitions(layers_filename)
    full_definitions(layers_filename)
      .select { |entry| entry["canEmbed"] }
      .to_h { |entry| [entry["layerId"], entry.slice("style", "styleDark", "isVectorStyle", "credit").compact] }
  end

  def self.insert_api_key(layer, key)
    if layer[key].include?("{apikey}") && !Settings[layer["apiKeyId"]]
      raise "API key for #{layer['apiKeyId']} is required but not set in settings."
    elsif layer[key].include?("{apikey}")
      layer[key].sub("{apikey}", Settings[layer["apiKeyId"]])
    else
      layer[key]
    end
  end

  def self.style_from_tile_url(layer, key)
    url_template = insert_api_key(layer, key)

    tiles = if layer["subdomains"]
              layer["subdomains"].map { |server| url_template.sub("{s}", server) }
            else
              [url_template]
            end

    {
      :version => 8,
      :sources => {
        "raster-tiles-#{layer['layerId']}" => {
          :type => "raster",
          :tiles => tiles,
          :tileSize => 256,
          :maxzoom => layer["maxZoom"]
        }
      },
      :layers => [
        {
          :id => "raster-tiles-layer-#{layer['layerId']}",
          :type => "raster",
          :source => "raster-tiles-#{layer['layerId']}"
        }
      ]
    }
  end
end
