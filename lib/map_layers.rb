module MapLayers
  def self.definitions(layers_filename)
    YAML.load_file(Rails.root.join(layers_filename)).filter_map do |layer|
      if layer["apiKeyId"]
        next unless Settings[layer["apiKeyId"]]

        layer["apikey"] = Settings[layer["apiKeyId"]]
        layer.delete "apiKeyId"
      end
      layer
    end
  end
end
