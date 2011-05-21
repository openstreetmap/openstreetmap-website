module ActionView
  module Helpers
    module AssetTagHelper
      def asset_path(source)
        compute_public_path(source, nil)
      end
    end
  end
end
