Rails.configuration.after_initialize do
  OsmCommunityIndex::LocalChapter.add_to_i18n
end
