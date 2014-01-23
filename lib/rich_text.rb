module RichText
  def self.new(format, text)
    case format
    when "html"; HTML.new(text || "")
    when "markdown"; Markdown.new(text || "")
    when "text"; Text.new(text || "")
    else; nil
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

      if doc.content.length > 0
        doc.xpath("//a").each do |link|
          link_count += 1
          link_size += link.content.length
        end

        link_proportion = link_size.to_f / doc.content.length.to_f
      else
        link_proportion = 0
      end

      return [link_proportion - 0.2, 0.0].max * 200 + link_count * 40
    end

  protected

    def simple_format(text)
      SimpleFormat.new.simple_format(text)
    end

    def linkify(text)
      if text.html_safe?
        Rinku.auto_link(text, :urls, tag_options(:rel => "nofollow")).html_safe
      else
        Rinku.auto_link(text, :urls, tag_options(:rel => "nofollow"))
      end
    end
  end

  class HTML < Base
    def to_html
      linkify(sanitize(simple_format(self)))
    end

    def to_text
      self.to_s
    end

  private

    def sanitize(text)
      Sanitize.clean(text, Sanitize::Config::OSM).html_safe
    end
  end

  class Markdown < Base
    def to_html
      html_parser.render(self).html_safe
    end

    def to_text
      self.to_s
    end

  private

    def html_parser
      @@html_renderer ||= Renderer.new({
        :filter_html => true, :safe_links_only => true
      })
      @@html_parser ||= Redcarpet::Markdown.new(@@html_renderer, {
        :no_intra_emphasis => true, :autolink => true, :space_after_headers => true
      })
    end

    class Renderer < Redcarpet::Render::XHTML
      def link(link, title, alt_text)
        "<a rel=\"nofollow\" href=\"#{link}\">#{alt_text}</a>"
      end

      def autolink(link, link_type)
        if link_type == :email
          "<a rel=\"nofollow\" href=\"mailto:#{link}\">#{link}</a>"
        else
          "<a rel=\"nofollow\" href=\"#{link}\">#{link}</a>"
        end
      end 
    end
  end

  class Text < Base
    def to_html
      linkify(simple_format(ERB::Util.html_escape(self)))
    end

    def to_text
      self.to_s
    end
  end
end
