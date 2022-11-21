module OpenStreetMap
  module Browser
    module Features
      def es6?
        chrome?(">44") || firefox?(">24") || safari?(">7") || edge?(">11") || generic_webkit?
      end

      def generic_webkit?
        webkit? && !chrome? && !safari? && !edge? && !phantom_js?
      end
    end
  end
end

Browser::Base.include(OpenStreetMap::Browser::Features)
