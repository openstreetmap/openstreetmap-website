if defined?(ActiveRecord::ConnectionAdaptors::AbstractAdapter)
  module ActiveRecord
    module ConnectionAdapters
      class AbstractAdapter
        protected

        alias_method :old_log, :log

        def log(sql, name)
          if block_given?
            old_log(sql, name) do
              yield
            end
          else
            old_log(sql, name)
          end
        rescue ActiveRecord::StatementInvalid => ex
          if ex.message =~ /^OSM::APITimeoutError: /
            raise OSM::APITimeoutError.new
          elsif ex.message =~ /^Timeout::Error: /
            raise Timeout::Error.new("time's up!")
          else
            raise
          end
        end
      end
    end
  end
end
