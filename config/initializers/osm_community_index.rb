Rails.configuration.after_initialize do
  OsmCommunityIndex.add_to_i18n
end
