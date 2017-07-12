if defined?(ActiveRecord::ConnectionAdaptors::AbstractAdapter)
  module OpenStreetMap
    module AbstractAdapter
      module PropagateTimeouts
        def translate_exception_class(e, sql)
          if e.is_a?(Timeout::Error) || e.is_a?(OSM::APITimeoutError)
            e
          else
            super(e, sql)
          end
        end
      end
    end
  end

  ActiveRecord::ConnectionAdaptors::AbstractAdapter.prepend(OpenStreetMap::AbstractAdapter::PropagateTimeouts)
end
