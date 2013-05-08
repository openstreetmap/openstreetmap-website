module ID
  LOCALES = Rails.root.join('vendor/assets/iD/iD/locales').entries.map {|p| p.basename.to_s[/(.*).json/] && $1 }.compact
end
