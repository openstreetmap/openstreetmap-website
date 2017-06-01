# Some versions of ruby seem to accidentally force the encoding
# as part of normalize_path and some don't

module OSM
  module Router
    module ForceEncoding
      def normalize_path(path)
        super(path).force_encoding("UTF-8")
      end
    end
  end
end

ActionDispatch::Journey::Router::Utils.singleton_class.prepend(OSM::Router::ForceEncoding)
