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

    def sanitize(text)
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

        link_proportion = link_size.to_f / doc.content.length.to_f
      end

      spammy_phrases = SPAMMY_PHRASES.count do |phrase|
        doc.content.include?(phrase)
      end

      [link_proportion - 0.2, 0.0].max * 200 +
        link_count * 40 +
        spammy_phrases * 40
    end

    protected

    def simple_format(text)
      SimpleFormat.new.simple_format(text)
    end

    def linkify(text)
      if text.html_safe?
        Rinku.auto_link(text, :urls, tag_builder.tag_options(:rel => "nofollow")).html_safe
      else
        Rinku.auto_link(text, :urls, tag_builder.tag_options(:rel => "nofollow"))
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

    private

    def sanitize(text)
      Sanitize.clean(text, Sanitize::Config::OSM).html_safe
    end
  end

  class Markdown < Base
    def to_html
      Markdown.html_parser.render(self).html_safe
    end

    def to_text
      to_s
    end

    def self.html_renderer
      @html_renderer ||= Redcarpet::Render::XHTML.new(:filter_html => true, :safe_links_only => true, :link_attributes => { :rel => "nofollow" })
    end

    def self.html_parser
      @html_parser ||= Redcarpet::Markdown.new(html_renderer, :no_intra_emphasis => true, :autolink => true, :space_after_headers => true)
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
