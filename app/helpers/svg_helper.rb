module SvgHelper
  def key_svg_tag(**options)
    border_width = options["border"] ? (options["border-width"] || 1) : 0
    rect_attrs = {
      :width => "100%",
      :height => "100%",
      :fill => options["fill"] || "none"
    }
    if border_width.positive?
      rect_attrs[:x] = rect_attrs[:y] = format("%g", 0.5 * border_width)
      rect_attrs[:width] = options["width"] - border_width
      rect_attrs[:height] = options["height"] - border_width
    end
    svg_attrs = options.slice("width", "height", "opacity", :class)

    tag.svg(**svg_attrs) do
      concat tag.rect(**rect_attrs, **stroke_attrs(options, "border")) if options["fill"] || options["border"]
      concat tag.line(:x2 => "100%", :y1 => "50%", :y2 => "50%", **stroke_attrs(options, "line")) if options["line"]
      if options["casing"]
        casing_width = options["casing-width"] || 1
        y_top = 0.5 * casing_width
        y_bottom = options["height"] - (0.5 * casing_width)
        concat tag.g(tag.line(:x2 => "100%", :y1 => y_top, :y2 => y_top) +
                     tag.line(:x2 => "100%", :y1 => y_bottom, :y2 => y_bottom),
                     **stroke_attrs(options, "casing"))
      end
    end
  end

  private

  def stroke_attrs(attrs, prefix)
    attrs.select { |key| key.start_with?(prefix) }.transform_keys { |key| key.delete_prefix(prefix).prepend("stroke") }
  end
end
