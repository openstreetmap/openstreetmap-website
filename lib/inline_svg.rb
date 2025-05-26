module InlineSvg
  def self.render(svg_source, attributes)
    svg = svg_source.dup
    title = attributes.delete(:title) || attributes.delete("title")

    svg.gsub!(" xmlns=\"http://www.w3.org/2000/svg\"", "")
    svg.gsub!(/(fill|stroke)="#ff00ff"/, "\\1=\"currentColor\"")
    svg.gsub!(/ style="[^"]+"/, "")

    svg.sub!(">", "><title>#{ERB::Util.html_escape(title)}</title>") if title
    svg.sub!("<svg", "<svg #{attributes.map { |k, v| %(#{k}="#{ERB::Util.html_escape(v)}") }.join(' ')}") if attributes.any?

    svg.html_safe # rubocop:disable Rails/OutputSafety
  end
end
