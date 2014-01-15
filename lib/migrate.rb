module ActiveRecord
  module ConnectionAdapters
    module SchemaStatements
      def quote_column_names(column_name)
        Array(column_name).map { |e| quote_column_name(e) }.join(", ")
      end

      def add_primary_key(table_name, column_name, options = {})
        column_names = Array(column_name)
        quoted_column_names = column_names.map { |e| quote_column_name(e) }.join(", ")
        execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (#{quoted_column_names})"
      end

      def remove_primary_key(table_name)
        execute "ALTER TABLE #{table_name} DROP PRIMARY KEY"
      end

      def add_foreign_key(table_name, column_name, reftbl, refcol = nil)
        execute "ALTER TABLE #{table_name} ADD " +
          "FOREIGN KEY (#{quote_column_names(column_name)}) " +
          "REFERENCES #{reftbl} (#{quote_column_names(refcol || column_name)})"
      end

      def remove_foreign_key(table_name, column_name, reftbl, refcol = nil)
        execute "ALTER TABLE #{table_name} DROP " +
          "CONSTRAINT #{table_name}_#{column_name[0]}_fkey"
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

    class PostgreSQLAdapter
      alias_method :old_native_database_types, :native_database_types

      def native_database_types
        types = old_native_database_types
        types[:double] = { :name => "double precision" }
        types[:integer_pk] = { :name => "serial PRIMARY KEY" }
        types[:bigint_pk] = { :name => "bigserial PRIMARY KEY" }
        types[:bigint_pk_64] = { :name => "bigserial PRIMARY KEY" }
        types[:bigint_auto_64] = { :name => "bigint" } #fixme: need autoincrement?
        types[:bigint_auto_11] = { :name => "bigint" } #fixme: need autoincrement?
        types[:bigint_auto_20] = { :name => "bigint" } #fixme: need autoincrement?
        types[:four_byte_unsigned] = { :name => "bigint" } # meh
        types[:inet] = { :name=> "inet" }

        enumerations.each_key do |e|
          types[e.to_sym]= { :name => e }
        end

        types
      end

      def myisam_table
        return { :id => false, :force => true, :options => ""}
      end

      def innodb_table
        return { :id => false, :force => true, :options => ""}
      end

      def innodb_option
        return ""
      end

      def change_engine (table_name, engine)
      end

      def add_fulltext_index (table_name, column)
        execute "CREATE INDEX #{table_name}_#{column}_idx on #{table_name} (#{column})"
      end

      def enumerations
        @enumerations ||= Hash.new
      end

      def create_enumeration(enumeration_name, values)
        enumerations[enumeration_name] = values
        execute "CREATE TYPE #{enumeration_name} AS ENUM ('#{values.join '\',\''}')"
      end

      def drop_enumeration(enumeration_name)
        execute "DROP TYPE #{enumeration_name}"
        enumerations.delete(enumeration_name)
      end

      def rename_enumeration(old_name, new_name)
        execute "ALTER TYPE #{quote_table_name(old_name)} RENAME TO #{quote_table_name(new_name)}"
      end

      def alter_primary_key(table_name, new_columns)
        execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{table_name}_pkey"
        execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (#{new_columns.join(',')})"
      end

      def interval_constant(interval)
        "'#{interval}'::interval"
      end

      def add_index(table_name, column_name, options = {})
        column_names = Array(column_name)
        index_name   = index_name(table_name, :column => column_names)

        if Hash === options # legacy support, since this param was a string
          index_type = options[:unique] ? "UNIQUE" : ""
          index_name = options[:name] || index_name
          index_method = options[:method] || "BTREE"
        else
          index_type = options
        end

        quoted_column_names = column_names.map { |e| quote_column_name(e) }
        if Hash === options and options[:lowercase]
          quoted_column_names = quoted_column_names.map { |e| "LOWER(#{e})" }
        end
        if Hash === options and options[:columns]
          quoted_column_names = quoted_column_names + Array[options[:columns]]
        end
        quoted_column_names = quoted_column_names.join(", ")

        execute "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} USING #{index_method} (#{quoted_column_names})"
      end

      def rename_index(table_name, old_name, new_name)
        execute "ALTER INDEX #{quote_table_name(old_name)} RENAME TO #{quote_table_name(new_name)}"
      end
    end
  end
end
