# frozen_string_literal: true

module TagLinker
  SECONDARY_WIKI_PREFIX_PATTERN = /[a-z:_-]+:/
  QID_PATTERN = /[Qq][1-9][0-9]*/

  # regex to match all wikipedia locale project identifiers
  WIKIPEDIA_PROJECT_IDENTIFIER_PATTERN = /[a-z]{2,3}(?:-[a-z]{2,3})?|be-tarask|roa-tara|simple|zh-classical|zh-min-nan/

  def self.init(paths)
    @tag2link_dict = build_tag2link_dict(JSON.parse(paths[:tag2link].read)).freeze
    @wiki_pages_dict = YAML.load_file(paths[:wiki_pages]).freeze
  end

  def self.wiki_link(type, title)
    locale = I18n.locale.to_s

    # update-wiki-pages does s/ /_/g on keys before saving them, we
    # have to replace spaces with underscore so we'll link
    # e.g. `source=Isle of Man Government aerial imagery (2001)' to
    # the correct page.
    lookup = title.tr(" ", "_")

    page = @wiki_pages_dict.dig(locale, type, lookup) ||
           @wiki_pages_dict.dig("en", type, lookup)

    url = "https://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}" if page

    url
  end

  def self.wikipedia_links(key, value)
    locale = I18n.locale.to_s
    # Some k/v's are wikipedia=http://en.wikipedia.org/wiki/Full%20URL
    return nil if %r{^https?://}.match?(value)

    if key =~ /^(?:#{SECONDARY_WIKI_PREFIX_PATTERN})?wikipedia(?::(#{WIKIPEDIA_PROJECT_IDENTIFIER_PATTERN}))?$/o
      lang = Regexp.last_match(1)
    else
      return nil
    end

    # Value could be a semicolon-separated list of Wikipedia pages
    value.split(";").map do |wiki_value|
      wiki_value = wiki_value.strip

      if wiki_value =~ /^(#{WIKIPEDIA_PROJECT_IDENTIFIER_PATTERN}):(.+)$/oi
        page_lang = Regexp.last_match(1)
        title_section = Regexp.last_match(2)
      else
        page_lang = lang
        return nil unless page_lang

        title_section = wiki_value
      end

      title, section = title_section.split("#", 2).map { |s| ERB::Util.u(s.tr(" ", "_")) }
      url = "https://#{page_lang}.wikipedia.org/wiki/#{title}?uselang=#{locale}"
      url += "##{section}" if section

      { :url => url, :title => wiki_value }
    end
  end

  def self.wikidata_links(key, value)
    locale = I18n.locale.to_s
    # The simple wikidata-tag (this is limited to only one value)
    if key == "wikidata" && value =~ /^#{QID_PATTERN}$/o
      return [{
        :url => "//www.wikidata.org/entity/#{value}?uselang=#{locale}",
        :title => value
      }]
    elsif key =~ /^#{SECONDARY_WIKI_PREFIX_PATTERN}wikidata$/o &&
          # Value has to be a semicolon-separated list of wikidata-IDs (whitespaces allowed before and after semicolons)
          value =~ /^#{QID_PATTERN}(?:\s*;\s*#{QID_PATTERN})*$/o
      # Splitting at every semicolon to get a separate hash for each wikidata-ID
      return value.split(";").map do |id|
        { :title => id, :url => "//www.wikidata.org/entity/#{id.strip}?uselang=#{locale}" }
      end
    end
    nil
  end

  def self.wikimedia_commons_link(key, value)
    locale = I18n.locale.to_s
    if key =~ /^(?:#{SECONDARY_WIKI_PREFIX_PATTERN})?wikimedia_commons$/o && value =~ /^(file|category):([^#]+)/i
      namespace = Regexp.last_match(1)
      title = Regexp.last_match(2)
      return {
        :url => "//commons.wikimedia.org/wiki/#{namespace}:#{ERB::Util.u title}?uselang=#{locale}",
        :title => value
      }
    end
    nil
  end

  def self.tag2link_link(key, value)
    # skip if it's a full URL
    return nil if %r{\Ahttps?://}.match?(value)

    url_template = @tag2link_dict[key]
    return nil unless url_template

    url_template.gsub("$1", value.sub(/^#/, ""))
  end

  def self.build_tag2link_dict(data)
    data
      # exclude deprecated, third-party, and non-HTTP URLs
      .reject { |item| item["rank"] == "deprecated" || item["source"] == "wikidata:P3303" || !item["url"].match?(%r{\Ahttps?://[^$]}) }
      .group_by { |item| item["key"].sub(/^Key:/, "") }
      .transform_values { |items| choose_best_tag2link_item(items) }
      .compact
      .transform_values { |items| items["url"] }
  end

  def self.choose_best_tag2link_item(items)
    return nil if items.blank?

    return items.first if items.size == 1

    # move preferred to the start of the array
    ranked = items.sort_by { |item| item["rank"] == "preferred" ? 0 : 1 }.uniq { |item| item["url"] }
    top_rank = ranked.first["rank"]
    top_items = ranked.select { |i| i["rank"] == top_rank }

    # if only one top-ranked item, prefer that
    return top_items.first if top_items.size == 1

    grouped = top_items.group_by { |i| i["source"] }
    return nil if grouped.size > 2

    # if both sources have exactly one preferred, prefer osmwiki
    return grouped["osmwiki:P8"]&.first || grouped.values.flatten.first if grouped.all? { |_s, vals| vals.size == 1 }

    # if one source has multiple preferreds and the other has one, prefer the single one
    return grouped.min_by { |_s, vals| vals.size }.last.first if grouped.any? { |_s, vals| vals.size == 1 }

    # exclude any that are ambiguous
    nil
  end
  private_class_method :choose_best_tag2link_item
end
