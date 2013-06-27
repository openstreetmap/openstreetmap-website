if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  module ActiveRecord
    module ConnectionAdapters
      class PostgreSQLAdapter
        def supports_disable_referential_integrity?() #:nodoc:
          version = query("SHOW server_version")[0][0].split('.')
          (version[0].to_i >= 9 || (version[0].to_i == 8 && version[1].to_i >= 1)) ? true : false
        rescue
          return false
        end

        def pk_and_sequence_for(table)
          # First try looking for a sequence with a dependency on the
          # given table's primary key.
          result = query(<<-end_sql, 'PK and serial sequence')[0]
            SELECT attr.attname, seq.relname
            FROM pg_class      seq,
                 pg_attribute  attr,
                 pg_depend     dep,
                 pg_namespace  name,
                 pg_constraint cons
            WHERE seq.oid           = dep.objid
              AND seq.relkind       = 'S'
              AND attr.attrelid     = dep.refobjid
              AND attr.attnum       = dep.refobjsubid
              AND attr.attrelid     = cons.conrelid
              AND attr.attnum       = cons.conkey[1]
              AND cons.contype      = 'p'
              AND dep.classid       = '"pg_class"'::regclass
              AND dep.refclassid    = '"pg_class"'::regclass
              AND dep.refobjid      = '#{quote_table_name(table)}'::regclass
          end_sql
  
          if result.nil? or result.empty?
            # If that fails, try parsing the primary key's default value.
            # Support the 7.x and 8.0 nextval('foo'::text) as well as
            # the 8.1+ nextval('foo'::regclass).
            result = query(<<-end_sql, 'PK and custom sequence')[0]
              SELECT attr.attname,
                CASE
                  WHEN split_part(def.adsrc, '''', 2) ~ '.' THEN
                    substr(split_part(def.adsrc, '''', 2),
                           strpos(split_part(def.adsrc, '''', 2), '.')+1)
                  ELSE split_part(def.adsrc, '''', 2)
                END
              FROM pg_class       t
              JOIN pg_attribute   attr ON (t.oid = attrelid)
              JOIN pg_attrdef     def  ON (adrelid = attrelid AND adnum = attnum)
              JOIN pg_constraint  cons ON (conrelid = adrelid AND adnum = conkey[1])
              WHERE t.oid = '#{quote_table_name(table)}'::regclass
                AND cons.contype = 'p'
                AND def.adsrc ~* 'nextval'
            end_sql
          end
  
          # [primary_key, sequence]
          [result.first, result.last]
        rescue
          nil
        end
      end

      class PostgreSQLColumn
        def simplified_type_with_enum(field_type)
          case field_type
          when /_enum$/
            :string
          else
            simplified_type_without_enum(field_type)
          end
        end

        alias_method_chain :simplified_type, :enum
      end
    end
  end
end
