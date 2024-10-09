begin
  BROWSE_IMAGE = YAML.load_file(Rails.root.join("config/browse_image.yml")).deep_symbolize_keys
rescue StandardError
  BROWSE_IMAGE = {}.freeze
end
