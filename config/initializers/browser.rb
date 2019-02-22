module OpenStreetMap
  module Browser
    module Features
      def html5?
        chrome? || firefox? || safari? || edge? || ie?(">8") || generic_webkit?
      end

      def es5?
        chrome? || firefox? || safari? || edge? || ie?(">8") || generic_webkit?
      end

      def es6?
        chrome?(">44") || firefox?(">24") || safari?(">7") || edge?(">11") || generic_webkit?
      end

      def generic_webkit?
        webkit? && !chrome? && !safari? && !edge?
      end
    end
  end
end

Browser::Base.include(OpenStreetMap::Browser::Features)
