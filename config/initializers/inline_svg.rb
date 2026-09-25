# frozen_string_literal: true

module OpenStreetMap
  class SvgToSymbolTransform < InlineSvg::CustomTransformation
    def transform(doc)
      with_svg(doc) do |svg|
        svg.name = "symbol"
      end
    end
  end

  class AssetRoutingTransform < InlineSvg::CustomTransformation
    def transform(doc)
      with_svg(doc) do |svg|
        svg.css("image").each do |image|
          image["href"] = ActionController::Base.helpers.asset_path(image["href"].sub(%r{\A[./]+}, ""))
        end
      end
    end
  end
end

InlineSvg.configure do |config|
  config.add_custom_transformation(:attribute => :to_symbol, :transform => OpenStreetMap::SvgToSymbolTransform)
  config.add_custom_transformation(:attribute => :asset_path, :transform => OpenStreetMap::AssetRoutingTransform, :default_value => true)
end
