if defined?(ActiveRecord::ConnectionAdaptors::QueryCache)
  module ActiveRecord
    module ConnectionAdapters
      module QueryCache
        private
          def cache_sql(sql)
  	  yield
          end
      end
    end
  end
end
