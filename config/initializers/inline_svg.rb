# frozen_string_literal: true

module OpenStreetMap
  class SvgToSymbolTransform < InlineSvg::CustomTransformation
    def transform(doc)
      with_svg(doc) do |svg|
        svg.name = "symbol"
      end
    end
  end
end

InlineSvg.configure do |config|
  config.add_custom_transformation(:attribute => :to_symbol, :transform => OpenStreetMap::SvgToSymbolTransform)
end
