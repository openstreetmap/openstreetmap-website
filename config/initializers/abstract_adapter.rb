if defined?(ActiveRecord::ConnectionAdaptors::AbstractAdapter)
  module ActiveRecord
    module ConnectionAdapters
      class AbstractAdapter
        protected

        alias old_log log

        def translate_exception_class_with_timeout(e, sql)
          if e.is_a?(Timeout::Error) || e.is_a?(OSM::APITimeoutError)
            e
          else
            translate_exception_class_without_timeout(e, sql)
          end
        end

        alias_method_chain :translate_exception_class, :timeout
      end
    end
  end
end
