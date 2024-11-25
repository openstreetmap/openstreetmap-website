begin
  BROWSE_ICONS = YAML.load_file(Rails.root.join("config/browse_icons.yml")).transform_values do |tag_key_data|
    transformed_tag_key_data = {}
    tag_key_data.each do |tag_value, tag_value_data|
      transformed_tag_key_data[tag_value] = tag_value_data.deep_symbolize_keys
    end
    transformed_tag_key_data
  end
rescue StandardError
  BROWSE_ICONS = {}.freeze
end
