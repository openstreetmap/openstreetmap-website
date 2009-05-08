module CompositePrimaryKeys
  module ActiveRecord
    module AttributeMethods #:nodoc:
      def self.append_features(base)
        super
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        # Define an attribute reader method.  Cope with nil column.
        def define_read_method(symbol, attr_name, column)
          cast_code = column.type_cast_code('v') if column
          cast_code = "::#{cast_code}" if cast_code && cast_code.match('ActiveRecord::.*')
          access_code = cast_code ? "(v=@attributes['#{attr_name}']) && #{cast_code}" : "@attributes['#{attr_name}']"

          unless self.primary_keys.include?(attr_name.to_sym)
            access_code = access_code.insert(0, "missing_attribute('#{attr_name}', caller) unless @attributes.has_key?('#{attr_name}'); ")
          end

          if cache_attribute?(attr_name)
            access_code = "@attributes_cache['#{attr_name}'] ||= (#{access_code})"
          end

          evaluate_attribute_method attr_name, "def #{symbol}; #{access_code}; end"
        end

        # Evaluate the definition for an attribute related method
        def evaluate_attribute_method(attr_name, method_definition, method_name=attr_name)
          unless primary_keys.include?(method_name.to_sym)
            generated_methods << method_name
          end

          begin
            class_eval(method_definition, __FILE__, __LINE__)
          rescue SyntaxError => err
            generated_methods.delete(attr_name)
            if logger
              logger.warn "Exception occurred during reader method compilation."
              logger.warn "Maybe #{attr_name} is not a valid Ruby identifier?"
              logger.warn "#{err.message}"
            end
          end
        end
      end

      # Allows access to the object attributes, which are held in the @attributes hash, as though they
      # were first-class methods. So a Person class with a name attribute can use Person#name and
      # Person#name= and never directly use the attributes hash -- except for multiple assigns with
      # ActiveRecord#attributes=. A Milestone class can also ask Milestone#completed? to test that
      # the completed attribute is not nil or 0.
      #
      # It's also possible to instantiate related objects, so a Client class belonging to the clients
      # table with a master_id foreign key can instantiate master through Client#master.
      def method_missing(method_id, *args, &block)
        method_name = method_id.to_s

        # If we haven't generated any methods yet, generate them, then
        # see if we've created the method we're looking for.
        if !self.class.generated_methods?
          self.class.define_attribute_methods

          if self.class.generated_methods.include?(method_name)
            return self.send(method_id, *args, &block)
          end
        end

        if self.class.primary_keys.include?(method_name.to_sym)
          ids[self.class.primary_keys.index(method_name.to_sym)]
        elsif md = self.class.match_attribute_method?(method_name)
          attribute_name, method_type = md.pre_match, md.to_s
          if @attributes.include?(attribute_name)
            __send__("attribute#{method_type}", attribute_name, *args, &block)
          else
            super
          end
        elsif @attributes.include?(method_name)
          read_attribute(method_name)
        else
          super
        end
      end
    end
  end
end
