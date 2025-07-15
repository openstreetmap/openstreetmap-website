module SvgHelper
  def notice_svg_tag
    path_data = "M 2 0 C 0.892 0 0 0.892 0 2 L 0 14 C 0 15.108 0.892 16 2 16 L 14 16 C 15.108 16 16 15.108 16 14 L 16 2 C 16 0.892 15.108 0 14 0 L 2 0 z M 7 3 L 9 3 L 9 8 L 7 8 L 7 3 z M 7 10 L 9 10 L 9 12 L 7 12 L 7 10 z"
    path_tag = tag.path :d => path_data, :fill => "currentColor"
    tag.svg path_tag, :width => 16, :height => 16
  end

  def previous_page_svg_tag(**)
    adjacent_page_svg_tag(dir == "rtl" ? 1 : -1, **)
  end

  def next_page_svg_tag(**)
    adjacent_page_svg_tag(dir == "rtl" ? -1 : 1, **)
  end

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

  # returns "<" shape if side == -1; ">" if side == 1
  def adjacent_page_svg_tag(side, **options)
    count = options[:count] || 1
    height = options[:height] || 15
    pad = 2
    segment = (0.5 * height) - pad
    width = (segment + (2 * count * pad)).ceil
    angled_line_data = "l#{side * segment},#{segment} l#{-side * segment},#{segment}"
    path_data = Array.new(count) { |i| "M#{side * ((2 * i) + 1) * pad},#{pad} #{angled_line_data}" }.join(" ")
    path_tag = tag.path :d => path_data, :fill => "none", :stroke => "currentColor", :"stroke-width" => 1.5
    view_box = "#{-width} 0 #{width} #{height}" if side.negative?
    tag.svg path_tag, :width => width, :height => height, :viewBox => view_box, :class => options[:class]
  end

  def stroke_attrs(attrs, prefix)
    attrs.select { |key| key.start_with?(prefix) }.transform_keys { |key| key.delete_prefix(prefix).prepend("stroke") }
  end
end
