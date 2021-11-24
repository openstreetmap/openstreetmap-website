module OsmCommunityIndex
  class LocalChapter
    attr_reader :id, :name, :url

    @localised_chapters = {}

    def initialize(id, name, url)
      @id = id
      @name = name
      @url = url
    end

    def self.local_chapters_with_locale(locale)
      load_local_chapter_localisation
      @localised_chapters[locale] ||= load_local_chapters(locale)
    end

    def self.load_local_chapter_localisation
      community_index = OsmCommunityIndex.community_index
      localisation_files = Dir.children(Rails.root.join("node_modules/osm-community-index/i18n/"))
      localisation_files.each do |file|
        locale = File.basename(file,".yaml")
        # rails wants en-GB but osm-community-index has en_GB
        locale_rails = locale.split("_").join("-")
        full_path = Rails.root.join("node_modules/osm-community-index/i18n/#{file}")
        locale_data = YAML.safe_load(File.read(full_path))[locale]

        community_index["resources"].each do |id, resource|
          resource.each do |key, value|
            next unless key == "type" && value == "osm-lc" && id != "OSMF"

            strings = locale_data[id] || {}
            strings['name'] = locale_data['name'] || resource["strings"]["name"] || resource["strings"]["community"]

            data = {}
            data["osm_community_index"] = {}
            data["osm_community_index"]["local_chapter"] = {}
            data["osm_community_index"]["local_chapter"][id] = strings
            # data["osm_community_index.local_chapter." + id] = localisation
            I18n.backend.store_translations locale_rails, data

            if locale == "en"
              puts locale_rails + " " + id + " " + data.to_s
            end
          end
        end
      end

    end

    def self.load_local_chapters(locale)
      community_index = OsmCommunityIndex.community_index
      localised_strings = OsmCommunityIndex.localised_strings(locale)
      local_chapters = []
      community_index["resources"].each do |id, resource|
        resource.each do |key, value|
          next unless key == "type" && value == "osm-lc" && id != "OSMF"

          strings = resource["strings"]
          name = localised_strings.dig(id, "name") || strings["name"] || strings["community"]
          url = strings["url"]
          local_chapters.push(LocalChapter.new(id, name, url))
        end
      end
      local_chapters
    end
  end
end
