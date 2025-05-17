module InlineSvg
  def self.put(filename, class_name: nil)
    cache_key = "inline_svg/#{[filename, class_name].compact.join('-')}"
    Rails.cache.fetch(cache_key) do
      svg = Rails.root.join("app/assets/icons/#{filename}.svg").read
      svg.gsub!(" xmlns=\"http://www.w3.org/2000/svg\"", "")
      svg.gsub!(/(fill|stroke)="#ff00ff"/, "\\1=\"currentColor\"")
      svg.gsub!(/ style="[^"]+"/, "")
      svg.gsub!("<svg", "<svg class=\"#{class_name}\"") if class_name
      svg.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
