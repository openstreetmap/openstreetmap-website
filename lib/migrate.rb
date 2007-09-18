module ActiveRecord
  module ConnectionAdapters
    module SchemaStatements
      def add_primary_key(table_name, column_name, options = {})
        column_names = Array(column_name)
        quoted_column_names = column_names.map { |e| quote_column_name(e) }.join(", ")
        execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (#{quoted_column_names})"
      end

      def remove_primary_key(table_name)
        execute "ALTER TABLE #{table_name} DROP PRIMARY KEY"
      end

      alias_method :old_options_include_default?, :options_include_default?

      def options_include_default?(options)
        return false if options[:options] =~ /AUTO_INCREMENT/i
        return old_options_include_default?(options)
      end

      alias_method :old_add_column_options!, :add_column_options!

      def add_column_options!(sql, options)
        sql << " UNSIGNED" if options[:unsigned]
        old_add_column_options!(sql, options)
        sql << " #{options[:options]}"
      end
    end

    class MysqlAdapter
      alias_method :old_native_database_types, :native_database_types

      def native_database_types
        types = old_native_database_types
        types[:bigint] = { :name => "bigint", :limit => 20 }
        types[:double] = { :name => "double" }
        types
      end

      def change_column(table_name, column_name, type, options = {})
        unless options_include_default?(options)
          options[:default] = select_one("SHOW COLUMNS FROM #{table_name} LIKE '#{column_name}'")["Default"]

          unless type == :string or type == :text
            options.delete(:default) if options[:default] = "";
          end
        end

        change_column_sql = "ALTER TABLE #{table_name} CHANGE #{column_name} #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        add_column_options!(change_column_sql, options)
        execute(change_column_sql) 
      end

      def myisam_table
        return { :id => false, :force => true, :options => "ENGINE=MyIsam" }
      end

      def innodb_table
        return { :id => false, :force => true, :options => "ENGINE=InnoDB" }
      end
    end
  end
end
