module ActiveRecord
  module Associations
    class AssociationScope
      def add_constraints(scope)
        tables = construct_tables

        chain.each_with_index do |reflection, i|
          table, foreign_table = tables.shift, tables.first

          if reflection.source_macro == :has_and_belongs_to_many
            join_table = tables.shift

            # CPK
            # scope = scope.joins(join(
            #  join_table,
            #  table[reflection.active_record_primary_key].
            #    eq(join_table[reflection.association_foreign_key])
            #))
            predicate = cpk_join_predicate(table, reflection.association_primary_key,
                                           join_table, reflection.association_foreign_key)
            scope = scope.joins(join(join_table, predicate))

            table, foreign_table = join_table, tables.first
          end

          if reflection.source_macro == :belongs_to
            if reflection.options[:polymorphic]
              key = reflection.association_primary_key(klass)
            else
              key = reflection.association_primary_key
            end

            foreign_key = reflection.foreign_key
          else
            key         = reflection.foreign_key
            foreign_key = reflection.active_record_primary_key
          end

          conditions = self.conditions[i]

          if reflection == chain.last
            # CPK
            # scope = scope.where(table[key].eq(owner[foreign_key]))
            predicate = cpk_join_predicate(table, key, owner, foreign_key)
            scope = scope.where(predicate)

            if reflection.type
              scope = scope.where(table[reflection.type].eq(owner.class.base_class.name))
            end

            conditions.each do |condition|
              if options[:through] && condition.is_a?(Hash)
                condition = { table.name => condition }
              end

              scope = scope.where(interpolate(condition))
            end
          else
            # CPK
            # constraint = table[key].eq(foreign_table[foreign_key])
            constraint = cpk_join_predicate(table, key, foreign_table, foreign_key)

            if reflection.type
              type = chain[i + 1].klass.base_class.name
              constraint = constraint.and(table[reflection.type].eq(type))
            end

            scope = scope.joins(join(foreign_table, constraint))

            unless conditions.empty?
              scope = scope.where(sanitize(conditions, table))
            end
          end
        end

        scope
      end
    end
  end
end
