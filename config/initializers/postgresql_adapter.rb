module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      alias_method :old_pk_and_sequence_for, :pk_and_sequence_for

      def pk_and_sequence_for(table)
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
          old_pk_and_sequence_for(table)
        else
          [result.first, result.last]
        end
      end
    end
  end
end
