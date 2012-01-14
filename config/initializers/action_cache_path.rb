module ActionController
  module Caching
    module Actions
      class ActionCachePath
        def initialize(controller, options = {}, infer_extension = true)
          if infer_extension
            @extension = controller.params[:format]
            options.reverse_merge!(:format => @extension) if options.is_a?(Hash)
          else
            @extension = options[:format]
          end

          path = controller.url_for(options).split(%r{://}).last
          @path = normalize!(path)
        end
      end
    end
  end
end
