module OsmCommunityIndex
  class OsmCommunityIndex
    require "yaml"

    @localised_strings = {}

    def self.community_index
      @community_index ||= community_index_from_json
    end

    def self.localised_strings(locale)
      @localised_strings[locale] ||= locale_hash_from_json(locale)
    end

    def self.community_index_from_json
      json_file = Rails.root.join("node_modules/osm-community-index/dist/resources.json")
      JSON.parse(File.read(json_file))
    end

    def self.locale_hash_from_json(locale_in)
      locale = locale_in.to_s.tr("-", "_")
      # try the passed in locale
      json = load_locale_json(locale)
      return json unless json.nil?

      # now try it without it's country part (eg 'en' instead of 'en_GB')
      shortened_locale = locale.split("_").first
      unless shortened_locale == locale
        json = load_locale_json(shortened_locale)
        return json unless json.nil?
      end

      # if nothing else works, then return "en"
      load_locale_json("en")
    end

    def self.load_locale_json(locale)
      json_path = Rails.root.join("node_modules/osm-community-index/i18n/#{locale}.yaml")
      return YAML.safe_load(File.read(json_path))[locale] if File.exist?(json_path)

      nil
    end
  end
end
