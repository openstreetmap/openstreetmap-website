# Some versions of ruby seem to accidentally force the encoding
# as part of normalize_path and some don't

module ActionDispatch
  module Journey
    class Router
      class Utils
        def self.normalize_path_with_encoding(path)
          normalize_path_without_encoding(path).force_encoding("UTF-8")
        end

        class << self
          alias_method_chain :normalize_path, :encoding
        end
      end
    end
  end
end
