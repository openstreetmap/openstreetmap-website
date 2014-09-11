# Monkey patch id_was into CPK pending upstream integration
# https://github.com/composite-primary-keys/composite_primary_keys/pull/236
module ActiveRecord
  class Base
    module CompositeInstanceMethods
      def id_was
        attribute_was("id")
      end
    end
  end
end
