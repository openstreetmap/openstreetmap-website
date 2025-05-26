module InlineSvg
  def self.render(svg_source, attributes)
    svg = svg_source.dup

    svg.gsub!(" xmlns=\"http://www.w3.org/2000/svg\"", "")
    svg.gsub!(/(fill|stroke)="#ff00ff"/, "\\1=\"currentColor\"")
    svg.gsub!(/ style="[^"]+"/, "")

    if attributes.any?
      attr_string = attributes.map { |k, v| %(#{k}="#{ERB::Util.html_escape(v)}") }.join(" ")
      svg.sub!("<svg", "<svg #{attr_string}")
    end

    svg.html_safe # rubocop:disable Rails/OutputSafety
  end
end
