if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  module ActiveRecord
    module ConnectionAdapters
      class PostgreSQLAdapter
        def initialize_type_map_with_enums
          OID.alias_type "format_enum", "text"
          OID.alias_type "gpx_visibility_enum", "text"
          OID.alias_type "note_status_enum", "text"
          OID.alias_type "note_event_enum", "text"
          OID.alias_type "nwr_enum", "text"
          OID.alias_type "user_role_enum", "text"
          OID.alias_type "user_status_enum", "text"

          initialize_type_map_without_enums
        end

        alias_method_chain :initialize_type_map, :enums
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
