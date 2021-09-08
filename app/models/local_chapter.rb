class LocalChapter

  attr_reader :id, :name, :url

  @localised_chapters = {}

  def initialize(id, name, url)
    @id = id
    @name = name
    @url = url
  end

  def self.local_chapters_with_locale(locale)
    @localised_chapters[locale] ||= load_local_chapters(locale)
  end

  protected

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