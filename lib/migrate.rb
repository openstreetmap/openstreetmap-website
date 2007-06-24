module ActiveRecord
  module ConnectionAdapters
    module SchemaStatements
      def add_primary_key(table_name, column_name, options = {})
        column_names = Array(column_name)
        quoted_column_names = column_names.map { |e| quote_column_name(e) }.join(", ")
        execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (#{quoted_column_names})"
      end

      alias_method :old_add_column_options!, :add_column_options!

      def add_column_options!(sql, options)
        old_add_column_options!(sql, options)
        sql << " #{options[:options]}"
      end

      alias_method :old_options_include_default?, :options_include_default?

      def options_include_default?(options)
        old_options_include_default?(options) && !(options[:options] =~ /AUTO_INCREMENT/i)
      end
    end

    class MysqlAdapter
      alias_method :old_native_database_types, :native_database_types

      def native_database_types
        types = old_native_database_types
        types[:bigint] = { :name => "bigint", :limit => 20 }
        types
      end
    end
  end
end

myisam_table = { :id => false, :force => true, :options => "ENGINE=MyIsam" }
innodb_table = { :id => false, :force => true, :options => "ENGINE=InnoDB" }
