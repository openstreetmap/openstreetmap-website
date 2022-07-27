module ID
  LOCALES = Locale.list(Rails.root.join("vendor/assets/iD/iD/locales").entries.filter_map { |p| p.basename.to_s[/(.*)\.min\.json/] && Regexp.last_match(1) })
end
