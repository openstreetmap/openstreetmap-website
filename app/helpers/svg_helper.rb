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
      horizontal = "H#{options['width']}"
      concat tag.rect(**rect_attrs, **stroke_attrs(options, "border")) if options["fill"] || options["border"]
      if options["line"]
        y_middle = format("%g", 0.5 * options["height"])
        concat tag.path(:d => "M0,#{y_middle} #{horizontal}", **stroke_attrs(options, "line"))
      end
      if options["casing"]
        casing_width = options["casing-width"] || 1
        y_top = format("%g", 0.5 * casing_width)
        y_bottom = format("%g", options["height"] - (0.5 * casing_width))
        concat tag.path(:d => "M0,#{y_top} #{horizontal} M0,#{y_bottom} #{horizontal}", **stroke_attrs(options, "casing"))
      end
    end
  end

  private

  def stroke_attrs(attrs, prefix)
    attrs.select { |key| key.start_with?(prefix) }.transform_keys { |key| key.delete_prefix(prefix).prepend("stroke") }
  end
end
