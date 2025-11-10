# frozen_string_literal: true

module ID
  ID_PATH = Rails.root.join("node_modules/@openstreetmap/id")
  LOCALES = Locale.list(Rails.root.join(ID_PATH, "dist/locales").entries.filter_map { |p| p.basename.to_s[/(.*)\.min\.json/] && Regexp.last_match(1) })
end
