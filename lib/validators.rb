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
          record.errors.add(attr, @@invalid_utf8_message) unless valid_utf8? value
        end
      end    
      
      ##
      # Checks that a string is valid UTF-8 by trying to convert it to UTF-8
      # using the iconv library, which is in the standard library.
      def valid_utf8?(str)
        return true if str.nil?
        Iconv.conv("UTF-8", "UTF-8", str)
        return true

      rescue
        return false
      end  
      
    end
  end
end
