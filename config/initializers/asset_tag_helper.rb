module ActionView
  module Helpers
    module AssetTagHelper
      def rewrite_asset_path!(source)
        asset_id = rails_asset_id(source)
        source << "/#{asset_id}" if !asset_id.blank?
      end
    end
  end
end
