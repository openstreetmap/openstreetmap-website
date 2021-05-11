if defined?(ActiveRecord::ConnectionAdapters::AbstractAdapter)
  module OpenStreetMap
    module ActiveRecord
      module PostgreSQLAdapter
        def quote_column_name(name)
          Array(name).map { |n| super(n) }.join(", ")
        end

        def add_primary_key(table_name, column_name, _options = {})
          table_name = quote_table_name(table_name)
          column_name = quote_column_name(column_name)

          execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (#{column_name})"
        end

        def remove_primary_key(table_name)
          table_name = quote_table_name(table_name)

          execute "ALTER TABLE #{table_name} DROP PRIMARY KEY"
        end

        def alter_primary_key(table_name, new_columns)
          constraint_name = quote_table_name("#{table_name}_pkey")
          table_name = quote_table_name(table_name)
          new_columns = quote_column_name(new_columns)

          execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{constraint_name}"
          execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (#{new_columns})"
        end

        def create_enumeration(enumeration_name, values)
          execute "CREATE TYPE #{enumeration_name} AS ENUM ('#{values.join '\',\''}')"
        end

        def drop_enumeration(enumeration_name)
          execute "DROP TYPE #{enumeration_name}"
        end

        def rename_enumeration(old_name, new_name)
          old_name = quote_table_name(old_name)
          new_name = quote_table_name(new_name)

          execute "ALTER TYPE #{old_name} RENAME TO #{new_name}"
        end
      end
    end
  end

  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(OpenStreetMap::ActiveRecord::PostgreSQLAdapter)
end
