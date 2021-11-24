module OsmCommunityIndex
  class LocalChapter
    attr_reader :id, :url

    def initialize(id, url)
      @id = id
      @url = url
    end

    def self.local_chapters
      @chapters = load_local_chapters
    end

    def self.load_local_chapters
      community_index = OsmCommunityIndex.community_index
      local_chapters = []
      community_index["resources"].each do |id, resource|
        resource.each do |key, value|
          next unless key == "type" && value == "osm-lc" && id != "OSMF"

          # name comes via I18n
          url = resource["strings"]["url"]
          local_chapters.push(LocalChapter.new(id, url))
        end
      end
      local_chapters
    end

    def self.add_to_i18n
      community_index = OsmCommunityIndex.community_index
      files = Dir.children(Rails.root.join("node_modules/osm-community-index/i18n/"))
      files.each do |file|
        path = Rails.root.join("node_modules/osm-community-index/i18n/#{file}")
        locale = File.basename(file,".yaml")
        community_index_yaml = YAML.safe_load(File.read(path))[locale]
        # rails wants en-GB but osm-community-index has en_GB
        locale_rails = locale.split("_").join("-")

        community_index["resources"].each do |id, resource|
          resource.each do |key, value|
            next unless key == "type" && value == "osm-lc" && id != "OSMF"

            strings = community_index_yaml[id] || {}
            # if the name isn't defined then fall back on community,
            # as per discussion here: https://github.com/osmlab/osm-community-index/issues/483
            strings['name'] = strings['name'] || resource["strings"]["name"] || resource["strings"]["community"]

            data = {}
            data["osm_community_index"] = {}
            data["osm_community_index"]["local_chapter"] = {}
            data["osm_community_index"]["local_chapter"][id] = strings
            I18n.backend.store_translations locale_rails, data

          end
        end
      end
    end
  end
end
