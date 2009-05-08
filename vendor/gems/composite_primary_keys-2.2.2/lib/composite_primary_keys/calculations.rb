module CompositePrimaryKeys
  module ActiveRecord
    module Calculations
      def self.append_features(base)
        super
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        def construct_calculation_sql(operation, column_name, options) #:nodoc:
          operation = operation.to_s.downcase
          options = options.symbolize_keys

          scope           = scope(:find)
          merged_includes = merge_includes(scope ? scope[:include] : [], options[:include])
          aggregate_alias = column_alias_for(operation, column_name)
          use_workaround  = !connection.supports_count_distinct? && options[:distinct] && operation.to_s.downcase == 'count'
          join_dependency = nil

          if merged_includes.any? && operation.to_s.downcase == 'count'
            options[:distinct] = true
            use_workaround  = !connection.supports_count_distinct?
            column_name = options[:select] || primary_key.map{ |part| "#{quoted_table_name}.#{connection.quote_column_name(part)}"}.join(',')
          end

          sql  = "SELECT #{operation}(#{'DISTINCT ' if options[:distinct]}#{column_name}) AS #{aggregate_alias}"

          # A (slower) workaround if we're using a backend, like sqlite, that doesn't support COUNT DISTINCT.
          sql = "SELECT COUNT(*) AS #{aggregate_alias}" if use_workaround

          sql << ", #{connection.quote_column_name(options[:group_field])} AS #{options[:group_alias]}" if options[:group]
          sql << " FROM (SELECT DISTINCT #{column_name}" if use_workaround
          sql << " FROM #{quoted_table_name} "
          if merged_includes.any?
            join_dependency = ::ActiveRecord::Associations::ClassMethods::JoinDependency.new(self, merged_includes, options[:joins])
            sql << join_dependency.join_associations.collect{|join| join.association_join }.join
          end

          add_joins!(sql, options[:joins], scope)
          add_conditions!(sql, options[:conditions], scope)
          add_limited_ids_condition!(sql, options, join_dependency) if \
            join_dependency &&
            !using_limitable_reflections?(join_dependency.reflections) &&
            ((scope && scope[:limit]) || options[:limit])

          if options[:group]
            group_key = connection.adapter_name == 'FrontBase' ?  :group_alias : :group_field
            sql << " GROUP BY #{connection.quote_column_name(options[group_key])} "
          end

          if options[:group] && options[:having]
            # FrontBase requires identifiers in the HAVING clause and chokes on function calls
            if connection.adapter_name == 'FrontBase'
              options[:having].downcase!
              options[:having].gsub!(/#{operation}\s*\(\s*#{column_name}\s*\)/, aggregate_alias)
            end

            sql << " HAVING #{options[:having]} "
          end

          sql << " ORDER BY #{options[:order]} " if options[:order]
          add_limit!(sql, options, scope)
          sql << ') w1' if use_workaround # assign a dummy table name as required for postgresql
          sql
        end
      end
    end
  end
end
