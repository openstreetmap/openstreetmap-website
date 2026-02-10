# frozen_string_literal: true

module RichText
  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_WORD_BREAK_THRESHOLD_LENGTH = 450
  URL_UNSAFE_CHARS = "[^\\w!#$%&'*+,./:;=?@_~^\\-]"

  def self.new(format, text)
    case format
    when "html" then HTML.new(text || "")
    when "markdown" then Markdown.new(text || "")
    when "text" then Text.new(text || "")
    end
  end

  class SimpleFormat
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::OutputSafetyHelper

    def sanitize(text, _options = {})
      Sanitize.clean(text, Sanitize::Config::OSM).html_safe
    end
  end

  class Base < String
    def image
      nil
    end

    def image_alt
      nil
    end

    def description
      nil
    end

    def truncate_html(max_length = nil, img_length = 1000)
      html_doc = to_html
      return html_doc if max_length.nil?

      doc = Nokogiri::HTML::DocumentFragment.parse(html_doc)
      keep_or_discards = %w[p h1 h2 h3 h4 h5 h6 pre a table ul ol dl]
      accumulated_length = 0
      exceeded_node_parent = nil
      truncated = false

      doc.traverse do |node|
        if accumulated_length >= max_length
          if node == exceeded_node_parent
            exceeded_node_parent = node.parent
            node.remove if keep_or_discards.include?(node.name)
          else
            node.remove
          end
          next
        end

        next unless node.children.empty?

        if node.text?
          accumulated_length += node.text.length
        elsif node.name == "img"
          accumulated_length += img_length
        end

        if accumulated_length >= max_length
          truncated = true
          exceeded_node_parent = node.parent
          node.remove
        end
      end

      {
        :truncated => truncated,
        :html => doc.to_html.html_safe
      }
    end

    protected

    def simple_format(text)
      SimpleFormat.new.simple_format(text, :dir => "auto")
    end

    def sanitize(text)
      Sanitize.clean(text, Sanitize::Config::OSM).html_safe
    end

    def linkify(text, mode = :urls, hosts: true, paths: true)
      link_attr = 'rel="nofollow noopener noreferrer" dir="auto"'
      html = ERB::Util.html_escape(text)

      html = expand_link_shorthands(html) if paths
      html = expand_host_shorthands(html) if hosts

      Rinku.auto_link(html, mode, link_attr) do |url|
        url = shorten_hosts(url) if hosts
        url = shorten_link(url) if paths

        url
      end.html_safe
    end

    private

    def gsub_pairs_for_linkify_detection
      Array
        .wrap(Settings.linkify&.detection_rules)
        .select { |rule| rule.path_template && rule.patterns.is_a?(Array) }
        .flat_map do |rule|
          expanded_path = "#{rule.host || "#{Settings.server_protocol}://#{Settings.server_url}"}/#{rule.path_template}"
          rule.patterns
              .select { |pattern| pattern.is_a?(String) }
              .map { |pattern| [Regexp.new("(?<=^|#{URL_UNSAFE_CHARS})#{pattern}", Regexp::IGNORECASE, :timeout => 0.01), expanded_path] }
        end
    end

    def expand_link_shorthands(text)
      gsub_pairs_for_linkify_detection
        .reduce(text) { |text, (pattern, replacement)| text.gsub(pattern, replacement) }
    end

    def expand_host_shorthands(text)
      Array
        .wrap(Settings.linkify&.normalisation_rules)
        .select { |rule| rule.host_replacement && rule.hosts&.any? }
        .reduce(text) do |text, rule|
          text.gsub(/(?<=^|#{URL_UNSAFE_CHARS})\b#{Regexp.escape(rule.host_replacement)}/) do
            "#{Settings.server_protocol}://#{rule.hosts[0]}"
          end
        end
    end

    def shorten_hosts(url)
      Array
        .wrap(Settings.linkify&.normalisation_rules)
        .reduce(url) { |url, rule| shorten_host(url, rule) }
    end

    def shorten_link(url)
      Array.wrap(Settings.linkify&.display_rules)
           .select { |rule| rule.pattern && rule.replacement }
           .reduce(url) { |url, rule| url.sub(Regexp.new(rule.pattern), rule.replacement) }
    end

    def shorten_host(url, rule)
      %r{^(https?://([^/]*))(.*)$}.match(url) do |m|
        scheme_host, host, path = m.captures
        if rule.hosts&.include?(host)
          path = path.sub(Regexp.new(rule.optional_path_prefix || ""), "")
          if rule.host_replacement
            "#{rule.host_replacement}#{path}"
          else
            "#{scheme_host}#{path}"
          end
        end || url
      end || url
    end
  end

  class HTML < Base
    def to_html
      linkify(simple_format(self), :paths => false)
    end

    def to_text
      to_s
    end
  end

  class Markdown < Base
    def to_html
      linkify(sanitize(document.to_html), :all, :paths => false)
    end

    def to_text
      to_s
    end

    def image
      @image_element = first_image_element(document.root) unless defined? @image_element
      @image_element.attr["src"] if @image_element
    end

    def image_alt
      @image_element = first_image_element(document.root) unless defined? @image_element
      @image_element.attr["alt"] if @image_element
    end

    def description
      return @description if defined? @description

      @description = first_truncated_text_content(document.root)
    end

    private

    def document
      return @document if @document

      @document = Kramdown::Document.new(self)

      should_get_dir_auto = lambda do |el|
        dir_auto_types = [:p, :header, :codespan, :codeblock, :pre, :ul, :ol, :table, :dl, :math]
        return true if dir_auto_types.include?(el.type)
        return true if el.type == :a && el.children.length == 1 && el.children[0].type == :text && el.children[0].value == el.attr["href"]

        false
      end

      add_dir = lambda do |element|
        element.attr["dir"] ||= "auto" if should_get_dir_auto.call(element)
        element.children.each(&add_dir)
      end
      add_dir.call(@document.root)

      @document
    end

    def first_image_element(element)
      return element if image?(element) && element.attr["src"].present?

      element.children.find do |child|
        nested_image = first_image_element(child)
        break nested_image if nested_image
      end
    end

    def first_truncated_text_content(element)
      if paragraph?(element)
        truncated_text_content(element)
      else
        element.children.find do |child|
          text = first_truncated_text_content(child)
          break text unless text.nil?
        end
      end
    end

    def truncated_text_content(element)
      text = +""

      append_text = lambda do |child|
        if child.type == :text
          text << child.value
        else
          child.children.each do |c|
            append_text.call(c)
            break if text.length > DESCRIPTION_MAX_LENGTH
          end
        end
      end
      append_text.call(element)

      return nil if text.blank?

      text_truncated_to_word_break = text.truncate(DESCRIPTION_MAX_LENGTH, :separator => /(?<!\s)\s+/)

      if text_truncated_to_word_break.length >= DESCRIPTION_WORD_BREAK_THRESHOLD_LENGTH
        text_truncated_to_word_break
      else
        text.truncate(DESCRIPTION_MAX_LENGTH)
      end
    end

    def image?(element)
      element.type == :img || (element.type == :html_element && element.value == "img")
    end

    def paragraph?(element)
      element.type == :p || (element.type == :html_element && element.value == "p")
    end
  end

  class Text < Base
    def to_html
      linkify(simple_format(ERB::Util.html_escape(self)))
    end

    def to_text
      to_s
    end
  end
end
