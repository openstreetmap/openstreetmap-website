# We need to restore field_changed? support until CPK is updated
module ActiveRecord
  module AttributeMethods
    module Dirty
    private
      alias_method :field_changed?, :_field_changed?
    end
  end
end
