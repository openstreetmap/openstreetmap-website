module OsmCommunityIndex
  class LocalChapter
    attr_reader :id, :url

    def initialize(id, url)
      @id = id
      @url = url
    end

    def self.local_chapters
      @chapters = init_local_chapters
    end

    def self.init_local_chapters
      raw_local_chapters = load_raw_local_chapters
      raw_local_chapters.map do |chapter|
        id = chapter[:id]
        url = chapter[:resource]["strings"]["url"]
        LocalChapter.new(id, url)
      end
    end

    def self.load_raw_local_chapters
      community_index = OsmCommunityIndex.community_index
      raw_local_chapters = []
      community_index["resources"].each do |id, resource|
        resource.each do |key, value|
          next unless key == "type" && value == "osm-lc" && id != "OSMF"

          raw_local_chapters.push({ :id => id, :resource => resource })
        end
      end
      raw_local_chapters
    end

    def self.add_to_i18n
      raw_local_chapters = load_raw_local_chapters
      files = Dir.glob(Rails.root.join("node_modules/osm-community-index/i18n/*"))
      files.each do |file|
        locale = File.basename(file, ".yaml")
        community_index_yaml = YAML.safe_load(File.read(file))[locale]
        # rails wants en-GB but osm-community-index has en_GB
        locale_rails = locale.tr("_", "-")
        data = {}

        raw_local_chapters.each do |chapter|
          id = chapter[:id]
          resource = chapter[:resource]

          strings = community_index_yaml[id] || {}
          # if the name isn't defined then fall back on community,
          # as per discussion here: https://github.com/osmlab/osm-community-index/issues/483
          strings["name"] = strings["name"] || resource["strings"]["name"] || resource["strings"]["community"]

          data.deep_merge!({ "osm_community_index" => { "local_chapter" => { id => strings } } })
        end

        I18n.backend.store_translations locale_rails, data
      end
    end
  end
end
