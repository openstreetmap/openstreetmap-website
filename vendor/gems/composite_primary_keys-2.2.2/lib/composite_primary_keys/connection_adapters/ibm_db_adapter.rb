module ActiveRecord
  module ConnectionAdapters
    class IBM_DBAdapter < AbstractAdapter
      
      # This mightn't be in Core, but count(distinct x,y) doesn't work for me
      def supports_count_distinct? #:nodoc:
        false
      end
      
      alias_method :quote_original, :quote
      def quote(value, column = nil)
        if value.kind_of?(String) && column && [:integer, :float].include?(column.type)
              value = column.type == :integer ? value.to_i : value.to_f
              value.to_s
        else
            quote_original(value, column)
        end
      end
    end
  end
end
