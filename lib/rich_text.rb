# frozen_string_literal: true

module RichText
  SPAMMY_PHRASES = [
    "Business Description:", "Additional Keywords:"
  ].freeze

  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_WORD_BREAK_THRESHOLD_LENGTH = 450

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
    def spam_score
      link_count = 0
      link_size = 0

      doc = Nokogiri::HTML(to_html)

      if doc.content.empty?
        link_proportion = 0
      else
        doc.xpath("//a").each do |link|
          link_count += 1
          link_size += link.content.length
        end

        link_proportion = link_size.to_f / doc.content.length
      end

      spammy_phrases = SPAMMY_PHRASES.count do |phrase|
        doc.content.include?(phrase)
      end

      ([link_proportion - 0.2, 0.0].max * 200) +
        (link_count * 40) +
        (spammy_phrases * 40)
    end

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

    def linkify(text, mode = :urls)
      link_attr = 'rel="nofollow noopener noreferrer" dir="auto"'
      Rinku.auto_link(ERB::Util.html_escape(text), mode, link_attr) do |url|
        url = shorten_host(url, Settings.linkify_hosts, Settings.linkify_hosts_replacement)
        shorten_host(url, Settings.linkify_wiki_hosts, Settings.linkify_wiki_hosts_replacement) do |path|
          path.sub(Regexp.new(Settings.linkify_wiki_optional_path_prefix || ""), "")
        end
      end.html_safe
    end

    private

    def shorten_host(url, hosts, hosts_replacement)
      %r{^(https?://([^/]*))(.*)$}.match(url) do |m|
        scheme_host, host, path = m.captures
        if hosts&.include?(host)
          path = yield(path) if block_given?
          if hosts_replacement
            "#{hosts_replacement}#{path}"
          else
            "#{scheme_host}#{path}"
          end
        end || url
      end || url
    end
  end

  class HTML < Base
    def to_html
      linkify(simple_format(self))
    end

    def to_text
      to_s
    end
  end

  class Markdown < Base
    def to_html
      linkify(sanitize(document.to_html), :all)
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
