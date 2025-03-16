module MapLayers
  def self.full_definitions(layers_filename)
    YAML.load_file(Rails.root.join(layers_filename))
        .reject { |layer| layer["apiKeyId"] && !Settings[layer["apiKeyId"]] }
        .map do |layer|
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
end
