module SvgHelper
  def solid_svg_image_tag(width, height, fill)
    svg = "<svg xmlns='http://www.w3.org/2000/svg' width='#{width}' height='#{height}'>" \
          "<rect width='100%' height='100%' fill='#{fill}' />" \
          "</svg>"
    escaped_svg = svg.gsub(/[\r\n%#()<>?\[\\\]^`{|}]/) { |c| u(c) }
    tag.img :src => "data:image/svg+xml,#{escaped_svg}", :escape => false
  end
end
