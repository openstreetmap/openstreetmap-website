module OpenStreetMap
  module Browser
    module Features
      def html5?
        webkit? || firefox? || safari? || edge? || ie?(">8")
      end

      def es5?
        webkit? || firefox? || safari? || edge? || ie?(">8")
      end

      def es6?
        webkit? || firefox? || safari? || edge?
      end
    end
  end
end

Browser::Base.include(OpenStreetMap::Browser::Features)
