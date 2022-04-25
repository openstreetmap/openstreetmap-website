begin
  BANNERS = YAML.load_file(Rails.root.join("config/banners.yml")).deep_symbolize_keys
rescue StandardError
  BANNERS = {}.freeze
end
