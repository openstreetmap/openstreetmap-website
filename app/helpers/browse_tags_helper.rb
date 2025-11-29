# frozen_string_literal: true

module BrowseTagsHelper
  def format_key(key)
    if url = TagParser.wiki_link("key", key)
      link_to h(key), url, :title => t("browse.tag_details.wiki_link.key", :key => key)
    else
      h(key)
    end
  end

  def format_value(key, value)
    if wp = TagParser.wikipedia_links(key, value)
      format_wikipedia_link(wp)
    elsif wdt = TagParser.wikidata_links(key, value)
      format_wikidata_link(wdt)
    elsif wmc = TagParser.wikimedia_commons_link(key, value)
      format_wikimedia_commons_link(wmc)
    elsif url = TagParser.wiki_link("tag", "#{key}=#{value}")
      link_to h(value), url, :title => t("browse.tag_details.wiki_link.tag", :key => key, :value => value)
    elsif email = TagParser.email_link(key, value)
      mail_to(email, :title => t("browse.tag_details.email_link", :email => email))
    elsif phones = TagParser.telephone_links(key, value)
      format_telephone_links(phones)
    elsif colour_value = TagParser.colour_preview(key, value)
      format_colour_preview(colour_value)
    else
      safe_join(value.split(";", -1).map { |x| tag2link_link(key, x) || linkify(h(x)) }, ";")
    end
  end

  private

  def tag2link_link(key, value)
    link = Tag2link.link(key, value)
    return nil unless link

    link_to(h(value), link, :rel => "nofollow")
  end

  def format_wikipedia_link(wp)
    wp = wp.map do |w|
      link_to(h(w[:title]), w[:url], :title => t("browse.tag_details.wikipedia_link", :page => w[:title]))
    end
    safe_join(wp, ";")
  end

  def format_wikidata_link(wdt)
    svg = button_tag :type => "button", :role => "button", :class => "btn btn-link float-end d-flex m-1 mt-0 me-n1 border-0 p-0 wdt-preview", :data => { :qids => wdt.pluck(:title) } do
      tag.svg :width => 27, :height => 16 do
        concat tag.title t("browse.tag_details.wikidata_preview", :count => wdt.length)
        concat tag.path :fill => "currentColor", :d => "M0 16h1V0h-1Zm2 0h3V0h-3Zm4 0h3V0h-3Zm4 0h1V0h-1Zm2 0h1V0h-1Zm2 0h1V0h-1Zm2 0h3V0h-3Zm4 0h1V0h-1Zm2 0h3V0h-3Zm4 0h1V0h-1Zm2 0h1V0h-1Z"
      end
    end
    wdt = wdt.map do |w|
      link_to(w[:title], w[:url], :title => t("browse.tag_details.wikidata_link", :page => w[:title].strip))
    end
    svg + safe_join(wdt, ";")
  end

  def format_wikimedia_commons_link(wmc)
    link_to h(wmc[:title]), wmc[:url], :title => t("browse.tag_details.wikimedia_commons_link", :page => wmc[:title])
  end

  def format_telephone_links(phones)
    phones = phones.map do |p|
      link_to(h(p[:phone_number]), p[:url], :title => t("browse.tag_details.telephone_link", :phone_number => p[:phone_number]))
    end
    safe_join(phones, "; ")
  end

  def format_colour_preview(colour_value)
    svg = tag.svg :width => 14, :height => 14, :class => "float-end m-1" do
      concat tag.title t("browse.tag_details.colour_preview", :colour_value => colour_value)
      concat tag.rect :x => 0.5, :y => 0.5, :width => 13, :height => 13, :fill => colour_value, :stroke => "#2222"
    end
    svg + colour_value
  end
end
