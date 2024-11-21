module MapLayers
  def self.definitions(layers_filename)
    YAML.load_file(Rails.root.join(layers_filename)).filter_map do |layer|
      if layer["apiKeyId"]
        if Settings.key?(layer["apiKeyId"].to_sym)
          layer["apiKey"] = Settings[layer["apiKeyId"]]
          layer.delete "apiKeyId"
          layer
        end
      else
        layer
      end
    end
  end
end
