require "redcarpet/render_strip"

module RichText
  def self.new(format, text)
    case format
    when "html"; HTML.new(text || "")
    when "markdown"; Markdown.new(text || "")
    else; nil
    end
  end

  class HTML < String
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::TagHelper

    def to_html
      linkify(sanitize(simple_format(self)))
    end

    def to_text
      self
    end

  private

    def sanitize(text)
      Sanitize.clean(text, Sanitize::Config::OSM).html_safe
    end

    def linkify(text)
      if text.html_safe?
        Rinku.auto_link(text, :urls, tag_options(:rel => "nofollow")).html_safe
      else
        Rinku.auto_link(text, :urls, tag_options(:rel => "nofollow"))
      end
    end
  end

  class Markdown < String
    def to_html
      html_parser.render(self).html_safe
    end

    def to_text
      text_parser.render(self)
    end

  private

    def html_parser
      @@html_renderer ||= Redcarpet::Render::XHTML.new({
        :filter_html => true, :safe_links_only => true
      })
      @@html_parser ||= Redcarpet::Markdown.new(@@html_renderer, {
        :no_intra_emphasis => true, :autolink => true, :space_after_headers => true
      })
    end

    def text_parser
      @@text_parser ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
    end
  end
end
