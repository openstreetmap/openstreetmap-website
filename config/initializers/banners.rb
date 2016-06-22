BANNERS = YAML.load_file("#{Rails.root}/config/banners.yml").deep_symbolize_keys rescue {}
