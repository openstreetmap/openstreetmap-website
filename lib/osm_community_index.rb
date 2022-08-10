module OsmCommunityIndex
  def self.add_to_i18n
    communities = Community.all
    files = Dir.glob(Rails.root.join("node_modules/osm-community-index/i18n/*.yaml"))
    files.each do |file|
      locale = File.basename(file, ".yaml")
      community_locale_yaml = YAML.safe_load(File.read(file))[locale]
      # rails wants language-COUNTRY but osm-community-index uses underscores
      locale_rails = locale.tr("_", "-")

      data = communities.each_with_object({}) do |community, obj|
        id = community.id

        strings = community_locale_yaml[id] || {}
        # if the name isn't defined then fall back on community,
        # as per discussion here: https://github.com/osmlab/osm-community-index/issues/483
        strings["name"] = strings["name"] || community.strings["name"] || community.strings["community"]

        obj.deep_merge!("osm_community_index" => { "communities" => { id => strings } })
      end

      I18n.backend.store_translations locale_rails, data
    end
  end
end
