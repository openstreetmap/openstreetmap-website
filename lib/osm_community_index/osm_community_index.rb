module OsmCommunityIndex
  class OsmCommunityIndex
    require "yaml"

    def self.community_index
      @community_index ||= community_index_from_json
    end

    def self.community_index_from_json
      json_file = Rails.root.join("node_modules/osm-community-index/dist/resources.json")
      JSON.parse(File.read(json_file))
    end
  end
end
