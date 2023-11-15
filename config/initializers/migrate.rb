if defined?(ActiveRecord::ConnectionAdapters::AbstractAdapter)
  module OpenStreetMap
    module PostgreSQL
      module Quoting
        def quote_column_name(name)
          Array(name).map { |n| super(n) }.join(", ")
        end
      end

      module SchemaStatements
        def add_primary_key(table_name, column_name, options = {})
          constraint_name = "#{table_name}_pkey"

          options = options.merge(:name => constraint_name, :unique => true)

          add_index(table_name, column_name, **options)
          set_primary_key table_name, constraint_name
        end

        def remove_primary_key(table_name)
          constraint_name = quote_table_name("#{table_name}_pkey")
          table_name = quote_table_name(table_name)

          execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{constraint_name}"
        end

        def alter_primary_key(table_name, column_name, options = {})
          constraint_name = "#{table_name}_pkey"
          tmp_constraint_name = "#{table_name}_pkey_tmp"

          options = options.merge(:name => tmp_constraint_name, :unique => true)

          add_index(table_name, column_name, **options)
          remove_primary_key table_name
          set_primary_key table_name, tmp_constraint_name
          rename_index table_name, tmp_constraint_name, constraint_name
        end

        def set_primary_key(table_name, constraint_name)
          constraint_name = quote_table_name(constraint_name)
          table_name = quote_table_name(table_name)

          execute "ALTER TABLE #{table_name} ADD PRIMARY KEY USING INDEX #{constraint_name}"
        end
      end
    end
  end

  ActiveRecord::ConnectionAdapters::PostgreSQL::Quoting.prepend(OpenStreetMap::PostgreSQL::Quoting)
  ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements.prepend(OpenStreetMap::PostgreSQL::SchemaStatements)
end
