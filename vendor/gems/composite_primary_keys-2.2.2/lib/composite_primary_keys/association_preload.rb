module CompositePrimaryKeys
  module ActiveRecord
    module AssociationPreload
      def self.append_features(base)
        super
        base.send(:extend, ClassMethods)
      end

      # Composite key versions of Association functions
      module ClassMethods
        def preload_has_and_belongs_to_many_association(records, reflection, preload_options={})
          table_name = reflection.klass.quoted_table_name
          id_to_record_map, ids = construct_id_map_for_composite(records)
          records.each {|record| record.send(reflection.name).loaded}
          options = reflection.options

          if composite?
            primary_key = reflection.primary_key_name.to_s.split(CompositePrimaryKeys::ID_SEP)
            where = (primary_key * ids.size).in_groups_of(primary_key.size).map do |keys|
              "(" + keys.map{|key| "t0.#{connection.quote_column_name(key)} = ?"}.join(" AND ") + ")"
            end.join(" OR ")

            conditions = [where, ids].flatten
            joins = "INNER JOIN #{connection.quote_table_name options[:join_table]} t0 ON #{full_composite_join_clause(reflection, reflection.klass.table_name, reflection.klass.primary_key, 't0', reflection.association_foreign_key)}"
            parent_primary_keys = reflection.primary_key_name.to_s.split(CompositePrimaryKeys::ID_SEP).map{|k| "t0.#{connection.quote_column_name(k)}"}
            parent_record_id = connection.concat(*parent_primary_keys.zip(["','"] * (parent_primary_keys.size - 1)).flatten.compact)
          else
            conditions = ["t0.#{connection.quote_column_name(reflection.primary_key_name)}  IN (?)", ids]
            joins = "INNER JOIN #{connection.quote_table_name options[:join_table]} t0 ON #{reflection.klass.quoted_table_name}.#{connection.quote_column_name(reflection.klass.primary_key)} = t0.#{connection.quote_column_name(reflection.association_foreign_key)})"
            parent_record_id = reflection.primary_key_name
          end

          conditions.first << append_conditions(reflection, preload_options)

          associated_records = reflection.klass.find(:all,
            :conditions => conditions,
            :include    => options[:include],
            :joins      => joins,
            :select     => "#{options[:select] || table_name+'.*'}, #{parent_record_id} as parent_record_id_",
            :order      => options[:order])

          set_association_collection_records(id_to_record_map, reflection.name, associated_records, 'parent_record_id_')
        end

        def preload_has_many_association(records, reflection, preload_options={})
          id_to_record_map, ids = construct_id_map_for_composite(records)
          records.each {|record| record.send(reflection.name).loaded}
          options = reflection.options

          if options[:through]
            through_records = preload_through_records(records, reflection, options[:through])
            through_reflection = reflections[options[:through]]
            through_primary_key = through_reflection.primary_key_name

            unless through_records.empty?
              source = reflection.source_reflection.name
              #add conditions from reflection!
              through_records.first.class.preload_associations(through_records, source, reflection.options)
              through_records.each do |through_record|
                key = through_primary_key.to_s.split(CompositePrimaryKeys::ID_SEP).map{|k| through_record.send(k)}.join(CompositePrimaryKeys::ID_SEP)
                add_preloaded_records_to_collection(id_to_record_map[key], reflection.name, through_record.send(source))
              end
            end
          else
            associated_records = find_associated_records(ids, reflection, preload_options)
            set_association_collection_records(id_to_record_map, reflection.name, associated_records, reflection.primary_key_name.to_s.split(CompositePrimaryKeys::ID_SEP))
          end
        end

        def preload_through_records(records, reflection, through_association)
          through_reflection = reflections[through_association]
          through_primary_key = through_reflection.primary_key_name

          if reflection.options[:source_type]
            interface = reflection.source_reflection.options[:foreign_type]
            preload_options = {:conditions => ["#{connection.quote_column_name interface} = ?", reflection.options[:source_type]]}

            records.compact!
            records.first.class.preload_associations(records, through_association, preload_options)

            # Dont cache the association - we would only be caching a subset
            through_records = []
            records.each do |record|
              proxy = record.send(through_association)

              if proxy.respond_to?(:target)
                through_records << proxy.target
                proxy.reset
              else # this is a has_one :through reflection
                through_records << proxy if proxy
              end
            end
            through_records.flatten!
          else
            records.first.class.preload_associations(records, through_association)
            through_records = records.map {|record| record.send(through_association)}.flatten
          end

          through_records.compact!
          through_records
        end

        def preload_belongs_to_association(records, reflection, preload_options={})
          options = reflection.options
          primary_key_name = reflection.primary_key_name.to_s.split(CompositePrimaryKeys::ID_SEP)

          if options[:polymorphic]
            raise AssociationNotSupported, "Polymorphic joins not supported for composite keys"
          else
            # I need to keep the original ids for each record (as opposed to the stringified) so
            # that they get properly converted for each db so the id_map ends up looking like:
            #
            # { '1,2' => {:id => [1,2], :records => [...records...]}}
            id_map = {}

            records.each do |record|
              key = primary_key_name.map{|k| record.send(k)}
              key_as_string = key.join(CompositePrimaryKeys::ID_SEP)

              if key_as_string
                mapped_records = (id_map[key_as_string] ||= {:id => key, :records => []})
                mapped_records[:records] << record
              end
            end


            klasses_and_ids = [[reflection.klass.name, id_map]]
          end

          klasses_and_ids.each do |klass_and_id|
            klass_name, id_map = *klass_and_id
            klass = klass_name.constantize
            table_name = klass.quoted_table_name
            connection = reflection.active_record.connection

            if composite?
              primary_key = klass.primary_key.to_s.split(CompositePrimaryKeys::ID_SEP)
              ids = id_map.keys.uniq.map {|id| id_map[id][:id]}

              where = (primary_key * ids.size).in_groups_of(primary_key.size).map do |keys|
                 "(" + keys.map{|key| "#{table_name}.#{connection.quote_column_name(key)} = ?"}.join(" AND ") + ")"
              end.join(" OR ")

              conditions = [where, ids].flatten
            else
              conditions = ["#{table_name}.#{connection.quote_column_name(primary_key)} IN (?)", id_map.keys.uniq]
            end

            conditions.first << append_conditions(reflection, preload_options)

            associated_records = klass.find(:all,
              :conditions => conditions,
              :include    => options[:include],
              :select     => options[:select],
              :joins      => options[:joins],
              :order      => options[:order])

            set_association_single_records(id_map, reflection.name, associated_records, primary_key)
          end
        end

        def set_association_collection_records(id_to_record_map, reflection_name, associated_records, key)
          associated_records.each do |associated_record|
            associated_record_key = associated_record[key]
            associated_record_key = associated_record_key.is_a?(Array) ? associated_record_key.join(CompositePrimaryKeys::ID_SEP) : associated_record_key.to_s
            mapped_records = id_to_record_map[associated_record_key]
            add_preloaded_records_to_collection(mapped_records, reflection_name, associated_record)
          end
        end

        def set_association_single_records(id_to_record_map, reflection_name, associated_records, key)
          seen_keys = {}
          associated_records.each do |associated_record|
            associated_record_key = associated_record[key]
            associated_record_key = associated_record_key.is_a?(Array) ? associated_record_key.join(CompositePrimaryKeys::ID_SEP) : associated_record_key.to_s

            #this is a has_one or belongs_to: there should only be one record.
            #Unfortunately we can't (in portable way) ask the database for 'all records where foo_id in (x,y,z), but please
            # only one row per distinct foo_id' so this where we enforce that
            next if seen_keys[associated_record_key]
            seen_keys[associated_record_key] = true
            mapped_records = id_to_record_map[associated_record_key][:records]
            mapped_records.each do |mapped_record|
              mapped_record.send("set_#{reflection_name}_target", associated_record)
            end
          end
        end

        def find_associated_records(ids, reflection, preload_options)
          options = reflection.options
          table_name = reflection.klass.quoted_table_name

          if interface = reflection.options[:as]
            raise AssociationNotSupported, "Polymorphic joins not supported for composite keys"
          else
            connection = reflection.active_record.connection
            foreign_key = reflection.primary_key_name
            conditions = ["#{table_name}.#{connection.quote_column_name(foreign_key)} IN (?)", ids]
            
            if composite?
              foreign_keys = foreign_key.to_s.split(CompositePrimaryKeys::ID_SEP)
            
              where = (foreign_keys * ids.size).in_groups_of(foreign_keys.size).map do |keys|
                "(" + keys.map{|key| "#{table_name}.#{connection.quote_column_name(key)} = ?"}.join(" AND ") + ")"
              end.join(" OR ")

              conditions = [where, ids].flatten
            end
          end

          conditions.first << append_conditions(reflection, preload_options)

          reflection.klass.find(:all,
            :select     => (preload_options[:select] || options[:select] || "#{table_name}.*"),
            :include    => preload_options[:include] || options[:include],
            :conditions => conditions,
            :joins      => options[:joins],
            :group      => preload_options[:group] || options[:group],
            :order      => preload_options[:order] || options[:order])
        end        
        
        # Given a collection of ActiveRecord objects, constructs a Hash which maps
        # the objects' IDs to the relevant objects. Returns a 2-tuple
        # <tt>(id_to_record_map, ids)</tt> where +id_to_record_map+ is the Hash,
        # and +ids+ is an Array of record IDs.
        def construct_id_map_for_composite(records)
          id_to_record_map = {}
          ids = []
          records.each do |record|
            primary_key ||= record.class.primary_key
            ids << record.id
            mapped_records = (id_to_record_map[record.id.to_s] ||= [])
            mapped_records << record
          end
          ids.uniq!
          return id_to_record_map, ids
        end
        
        def full_composite_join_clause(reflection, table1, full_keys1, table2, full_keys2)
          connection = reflection.active_record.connection
          full_keys1 = full_keys1.split(CompositePrimaryKeys::ID_SEP) if full_keys1.is_a?(String)
          full_keys2 = full_keys2.split(CompositePrimaryKeys::ID_SEP) if full_keys2.is_a?(String)
          where_clause = [full_keys1, full_keys2].transpose.map do |key_pair|
            quoted1 = connection.quote_table_name(table1)
            quoted2 = connection.quote_table_name(table2)
            "#{quoted1}.#{connection.quote_column_name(key_pair.first)}=#{quoted2}.#{connection.quote_column_name(key_pair.last)}"
          end.join(" AND ")
          "(#{where_clause})"
        end
      end
    end
  end
end
