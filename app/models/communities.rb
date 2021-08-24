
class Communities

  require 'yaml'

  @local_chapters = {}

  def self.local_chapters(locale)
    puts "locale is "+ locale.to_s
    @local_chapters[locale] = self.local_chapter_for(locale)
  end

  protected

  def self.local_chapter_for(locale)

    @local_chapters_index = self.load_local_chapters

    locale_dict = self.locale_dict_for(locale)

    localised_chapters = []
    @local_chapters_index.each do |chapter|
      id = chapter[:id]
      name = locale_dict.dig(id,"name") || chapter[:name]
      url = chapter[:url]
      localised_chapters.push({ id: id, name: name, url: url })
    end
    puts localised_chapters
    localised_chapters
  end

  def self.load_local_chapters

    json_file = File.expand_path("node_modules/osm-community-index/dist/resources.json", Dir.pwd);
    community_index = JSON.parse(File.read(json_file))

    local_chapters = []
    community_index['resources'].each do |id, resource|
      resource.each do |key, value|
        if key == "type" and value == "osm-lc" and id != "OSMF"
          strings = resource['strings']
          chapter_name = strings['community'] ||strings['name']
          url = strings['url']
          local_chapters.push({ id: id, name: chapter_name, url: url})
        end
      end
    end
    return local_chapters
  end


  def self.locale_dict_for(localeIn)
    locale = localeIn.to_s.gsub("-","_")
    full_local_path = File.expand_path("node_modules/osm-community-index/i18n/"+locale+".yaml", Dir.pwd)
    locale_dict = {}
    if File.exists?(full_local_path)
      locale_dict = YAML.load(File.read(full_local_path))[locale]
    else
      shortened_locale = locale.split("_").first
      if shortened_locale != locale
        shortened_local_path = File.expand_path("node_modules/osm-community-index/i18n/"+shortened_locale+".yaml", Dir.pwd)
        if File.exists?(shortened_local_path)
          locale_dict = YAML.load(File.read(shortened_local_path))[shortened_locale]
        end
      end
    end
    return locale_dict
  end

end
