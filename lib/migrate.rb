module OpenStreetMap
  module ActiveRecord
    module AbstractAdapter
      def add_index_options(table_name, column_name, options = {})
        columns = options.delete(:columns)
        index_name, index_type, index_columns, index_options, algorithm, using = super(table_name, column_name, options)
        [index_name, index_type, columns || index_columns, index_options, algorithm, using]
      end
    end

    module PostgreSQLAdapter
      def quote_column_name(name)
        Array(name).map { |n| super(n) }.join(", ")
      end

      def add_primary_key(table_name, column_name, _options = {})
        execute "ALTER TABLE #{quote_table_name(table_name)} ADD PRIMARY KEY (#{quote_column_name(column_name)})"
      end

      def remove_primary_key(table_name)
        execute "ALTER TABLE #{quote_table_name(table_name)} DROP PRIMARY KEY"
      end

      def alter_primary_key(table_name, new_columns)
        execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{quote_table_name(table_name + '_pkey')}"
        execute "ALTER TABLE #{quote_table_name(table_name)} ADD PRIMARY KEY (#{quote_column_name(new_columns)})"
      end

      def create_enumeration(enumeration_name, values)
        execute "CREATE TYPE #{enumeration_name} AS ENUM ('#{values.join '\',\''}')"
      end

      def drop_enumeration(enumeration_name)
        execute "DROP TYPE #{enumeration_name}"
      end

      def rename_enumeration(old_name, new_name)
        execute "ALTER TYPE #{quote_table_name(old_name)} RENAME TO #{quote_table_name(new_name)}"
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(OpenStreetMap::ActiveRecord::AbstractAdapter)
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(OpenStreetMap::ActiveRecord::PostgreSQLAdapter)
