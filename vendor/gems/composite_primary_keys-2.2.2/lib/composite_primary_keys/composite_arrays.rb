module CompositePrimaryKeys
  ID_SEP     = ','
  ID_SET_SEP = ';'

  module ArrayExtension
    def to_composite_keys
      CompositeKeys.new(self)
    end

    def to_composite_ids
      CompositeIds.new(self)
    end
  end

  class CompositeArray < Array
    def to_s
      join(ID_SEP)
    end
  end

  class CompositeKeys < CompositeArray

  end

  class CompositeIds < CompositeArray

  end
end

Array.send(:include, CompositePrimaryKeys::ArrayExtension)
