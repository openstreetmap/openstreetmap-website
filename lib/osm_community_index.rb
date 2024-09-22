module OsmCommunityIndex
  def self.add_to_i18n
    # Filter the communities here to avoid loading excessive numbers of translations
    communities = Community.where(:type => "osm-lc").where.not(:id => "OSMF")
    community_en_yaml = if File.exist?("node_modules/osm-community-index/i18n/en.yaml")
                          YAML.safe_load_file("node_modules/osm-community-index/i18n/en.yaml")["en"]
                        else
                          {}
                        end

    files = Rails.root.glob("node_modules/osm-community-index/i18n/*.yaml")
    files.each do |file|
      locale = File.basename(file, ".yaml")
      community_locale_yaml = YAML.safe_load_file(file)[locale]
      # rails wants language-COUNTRY but osm-community-index uses underscores
      locale_rails = locale.tr("_", "-")

      data = communities.each_with_object({}) do |community, obj|
        id = community.id

        strings = community_locale_yaml[id] || {}
        strings["name"] = resolve_name(community, community_locale_yaml, community_en_yaml)

        obj.deep_merge!("osm_community_index" => { "communities" => { id => strings } })
      end

      I18n.backend.store_translations locale_rails, data
    end
  end

  def self.resolve_name(community, community_locale_yaml, community_en_yaml)
    # If theres an explicitly translated name then use that
    translated_name = community_locale_yaml.dig(community.id, "name")
    return translated_name if translated_name

    # If not, then look up the default translated name for this type of community, and interpolate the template
    template = community_locale_yaml.dig("_defaults", community.type, "name") ||
               community_en_yaml.dig("_defaults", community.type, "name")
    community_name = community_locale_yaml.dig("_communities", community.strings["communityID"])
    # Change the `{community}` placeholder to `%{community}` and use Ruby's Kernel.format to fill it in.
    begin
      translated_name = format(template.gsub("{", "%{"), { :community => community_name }) if template && community_name
    rescue KeyError => e
      Rails.logger.warn e.full_message
    end
    return translated_name if translated_name

    # Otherwise fall back to the (English-language) resource name
    return community.strings["name"] if community.strings["name"]

    # Finally use the (English-language) community name
    community.strings["community"]
  end
end
