class Communities
  require "yaml"

  @local_chapters = {}

  def self.local_chapters(locale)
    @local_chapters[locale] ||= local_chapter_for(locale)
  end

  def self.local_chapter_for(locale)
    @local_chapters_index ||= load_local_chapters
    locale_dict = locale_dict_for(locale)
    localised_chapters = []
    @local_chapters_index.each do |chapter|
      id = chapter[:id]
      name = locale_dict.dig(id, "name") || chapter[:name]
      url = chapter[:url]
      localised_chapters.push({ :id => id, :name => name, :url => url })
    end
    localised_chapters
  end

  def self.load_local_chapters
    json_file = File.expand_path("node_modules/osm-community-index/dist/resources.json", Dir.pwd)
    community_index = JSON.parse(File.read(json_file))
    local_chapters = []
    community_index["resources"].each do |id, resource|
      resource.each do |key, value|
        next unless key == "type" && value == "osm-lc" && id != "OSMF"

        strings = resource["strings"]
        chapter_name = strings["community"] || strings["name"]
        url = strings["url"]
        local_chapters.push({ :id => id, :name => chapter_name, :url => url })
      end
    end
    local_chapters
  end

  def self.locale_dict_for(locale_in)
    locale = locale_in.to_s.tr("-", "_")
    full_local_path = File.expand_path("node_modules/osm-community-index/i18n/#{locale}.yaml", Dir.pwd)
    locale_dict = {}
    if File.exist?(full_local_path)
      locale_dict = YAML.safe_load(File.read(full_local_path))[locale]
    else
      shortened_locale = locale.split("_").first
      if shortened_locale != locale
        shortened_local_path = File.expand_path("node_modules/osm-community-index/i18n/#{shortened_locale}.yaml", Dir.pwd)
        locale_dict = YAML.safe_load(File.read(shortened_local_path))[shortened_locale] if File.exist?(shortened_local_path)
      end
    end
    locale_dict
  end
end
