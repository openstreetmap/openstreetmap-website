# frozen_string_literal: true

module BrowseHelper
  def element_icon(type, object)
    selected_icon_data = { :filename => "#{type}.svg", :priority => 1 }

    unless object.redacted?
      target_tags = object.tags.find_all { |k, _v| BROWSE_ICONS.key? k }.sort
      title = target_tags.map { |k, v| "#{k}=#{v}" }.to_sentence unless target_tags.empty?

      target_tags.each do |k, v|
        icon_data = BROWSE_ICONS[k][v] || BROWSE_ICONS[k][:*]
        selected_icon_data = icon_data if icon_data && icon_data[:priority] > selected_icon_data[:priority]
      end
    end

    image_tag "browse/#{selected_icon_data[:filename]}",
              :size => 20,
              :class => ["align-bottom object-fit-none browse-icon", { "browse-icon-invertible" => selected_icon_data[:invert] }],
              :title => title
  end

  def element_single_current_link(type, object)
    link_to object, { :rel => (link_follow(object) if type == "node") } do
      element_strikethrough object do
        printable_element_name object
      end
    end
  end

  def element_list_item(type, object, &)
    tag.li(tag.div(element_icon(type, object) + tag.div(:class => "align-self-center", &), :class => "d-flex gap-1"))
  end

  def element_list_item_with_strikethrough(type, object, &)
    element_list_item type, object do
      element_strikethrough object, &
    end
  end

  def printable_element_name(object)
    id = if object.id.is_a?(Array)
           object.id[0]
         else
           object.id
         end
    name = id.to_s

    # don't look at object tags if redacted, so as to avoid giving
    # away redacted version tag information.
    unless object.redacted?
      feature_name = feature_name(object.tags)
      name = t "printable_name.with_name_html", :name => tag.bdi(feature_name), :id => tag.bdi(id.to_s) if feature_name.present?
    end

    name
  end

  def printable_element_version(object)
    t "printable_name.version", :version => object.version
  end

  def element_strikethrough(object, &)
    if object.redacted? || !object.visible?
      tag.del(&)
    else
      yield
    end
  end

  def link_follow(object)
    "nofollow" if object.tags.empty?
  end

  def format_key(key)
    render_link(TagParser.parse_key(key))
  end

  def format_value(key, value, render_widgets: false)
    html = TagParser.parse_value(key, value).filter_map do |hash|
      if hash[:widget]
        render_widget(hash[:widget], **hash.except(:text, :url, :type, :widget)) if render_widgets
      else
        [render_link(hash), ";"]
      end
    end.flatten

    html.pop if html.last == ";"
    safe_join(html)
  end

  private

  def feature_name(tags)
    return nil if tags.empty?

    locale_keys = preferred_languages.expand.map { |locale| "name:#{locale}" }

    (locale_keys + %w[name ref addr:housename]).each do |key|
      return tags[key] if tags[key]
    end
    return "#{tags['addr:housenumber']} #{tags['addr:street']}" if tags["addr:housenumber"] && tags["addr:street"]

    nil
  end

  def render_widget(widget, **options)
    title = t("browse.tag_details.#{widget}", **options.slice(:count, :colour_value))
    case widget
    when :wikidata_preview
      button_tag(:type => "button", :role => "button", :class => "btn btn-link float-end d-flex m-1 mt-0 me-n1 border-0 p-0 wdt-preview", :data => options.slice(:qids)) do
        tag.svg :width => 27, :height => 16 do
          concat tag.title title
          concat tag.path :fill => "currentColor", :d => "M0 16h1V0h-1Zm2 0h3V0h-3Zm4 0h3V0h-3Zm4 0h1V0h-1Zm2 0h1V0h-1Zm2 0h3V0h-3Zm4 0h1V0h-1Zm2 0h3V0h-3Zm4 0h1V0h-1Zm2 0h1V0h-1Z"
        end
      end
    when :colour_preview
      tag.svg(:width => 14, :height => 14, :class => "float-end m-1") do
        concat tag.title title
        concat tag.rect :x => 0.5, :y => 0.5, :width => 13, :height => 13, :fill => options[:colour_value], :stroke => "#2222"
      end
    end
  end

  def render_link(hash)
    if hash[:url]
      link_helper = hash[:type] == :email_link ? :mail_to : :link_to
      link_options =
        if hash[:type] == :tag2link_link
          { :rel => "nofollow" }
        else
          { :title => t("browse.tag_details.#{hash[:type]}", **hash.except(:text, :url, :type)) }
        end

      send(link_helper, hash[:text], hash[:url], **link_options)
    else
      hash[:text]
    end
  end
end
