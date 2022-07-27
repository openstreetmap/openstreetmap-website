module OsmCommunityIndex
  class LocalChapter
    def self.add_to_i18n
      local_chapters = Community.where(:type => "osm-lc").where.not(:id => "OSMF")
      files = Dir.glob(Rails.root.join("node_modules/osm-community-index/i18n/*"))
      files.each do |file|
        locale = File.basename(file, ".yaml")
        community_index_yaml = YAML.safe_load(File.read(file))[locale]
        # rails wants en-GB but osm-community-index has en_GB
        locale_rails = locale.tr("_", "-")
        data = {}

        local_chapters.each do |chapter|
          id = chapter[:id]

          strings = community_index_yaml[id] || {}
          # if the name isn't defined then fall back on community,
          # as per discussion here: https://github.com/osmlab/osm-community-index/issues/483
          strings["name"] = strings["name"] || chapter["strings"]["name"] || chapter["strings"]["community"]

          data.deep_merge!({ "osm_community_index" => { "local_chapter" => { id => strings } } })
        end

        I18n.backend.store_translations locale_rails, data
      end
    end
  end
end
