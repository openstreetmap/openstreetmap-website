module RichText
  SPAMMY_PHRASES = [
    "Business Description:", "Additional Keywords:"
  ].freeze

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
    include ActionView::Helpers::TagHelper

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

    protected

    def simple_format(text)
      SimpleFormat.new.simple_format(text)
    end

    def sanitize(text)
      Sanitize.clean(text, Sanitize::Config::OSM).html_safe
    end

    def linkify(text, mode = :urls)
      if text.html_safe?
        Rinku.auto_link(text, mode, tag_builder.tag_options(:rel => "nofollow noopener noreferrer")).html_safe
      else
        Rinku.auto_link(text, mode, tag_builder.tag_options(:rel => "nofollow noopener noreferrer"))
      end
    end
  end

  class HTML < Base
    def to_html
      linkify(sanitize(simple_format(self)))
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
      @paragraph_element = first_paragraph_element(document.root) unless defined? @paragraph_element
      text_content(@paragraph_element) if @paragraph_element
    end

    private

    def document
      @document ||= Kramdown::Document.new(self)
    end

    def first_image_element(element)
      return element if image?(element) && element.attr["src"].present?

      element.children.find do |child|
        nested_image = first_image_element(child)
        break nested_image if nested_image
      end
    end

    def first_paragraph_element(element)
      return element if paragraph?(element)

      element.children.find do |child|
        nested_paragraph = first_paragraph_element(child)
        break nested_paragraph if nested_paragraph
      end
    end

    def text_content(element)
      text = ""

      append_text = lambda do |child|
        if child.type == :text
          text << child.value
        else
          child.children.each { |c| append_text.call(c) }
        end
      end
      append_text.call(element)

      text
    end

    def image?(element)
      element.type == :img || (element.type == :html_element && element.value == "img")
    end

    def paragraph?(element)
      element.type == :p
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
