module SvgHelper
  def solid_svg_tag(width, height, fill, **options)
    tag.svg :width => width, :height => height, **options do
      tag.rect :width => "100%", :height => "100%", :fill => fill
    end
  end
end
