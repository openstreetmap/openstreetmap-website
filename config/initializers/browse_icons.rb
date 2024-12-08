begin
  BROWSE_ICONS = YAML.load_file(Rails.root.join("config/browse_icons.yml")).deep_symbolize_keys
rescue StandardError
  BROWSE_ICONS = {}.freeze
end
