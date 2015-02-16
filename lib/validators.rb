module ActiveRecord
  module Validations
    module ClassMethods
      # error message when invalid UTF-8 is detected
      @@invalid_utf8_message = " is invalid UTF-8"

      ##
      # validation method to be included like any other validations methods
      # in the models definitions. this one checks that the named attribute
      # is a valid UTF-8 format string.
      def validates_as_utf8(*attrs)
        validates_each(attrs) do |record, attr, value|
          record.errors.add(attr, @@invalid_utf8_message) unless UTF8.valid? value
        end
      end
    end
  end
end
