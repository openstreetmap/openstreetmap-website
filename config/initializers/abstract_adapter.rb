# frozen_string_literal: true

if defined?(ActiveRecord::ConnectionAdapters::AbstractAdapter)
  module OpenStreetMap
    module AbstractAdapter
      module PropagateTimeouts
        def translate_exception_class(e, sql, binds)
          if e.is_a?(Timeout::Error) || e.is_a?(OSM::APITimeoutError)
            e
          else
            super
          end
        end
      end
    end
  end

  ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(OpenStreetMap::AbstractAdapter::PropagateTimeouts)
end
