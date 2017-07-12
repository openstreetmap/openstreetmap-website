# Some versions of ruby seem to accidentally force the encoding
# as part of normalize_path and some don't

module OpenStreetMap
  module Router
    module ForceEncoding
      def normalize_path(path)
        super(path).force_encoding("UTF-8")
      end
    end
  end
end

ActionDispatch::Journey::Router::Utils.singleton_class.prepend(OpenStreetMap::Router::ForceEncoding)
