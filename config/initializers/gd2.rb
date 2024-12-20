module OpenStreetMap
  module GD2
    module AnimatedGif
      def frames_finalizer
        proc do
          @frames.each do |frame|
            ::GD2::GD2FFI.send(:gdFree, frame.ptr)
          end
        end
      end
    end
  end
end

GD2::AnimatedGif.prepend(OpenStreetMap::GD2::AnimatedGif)
