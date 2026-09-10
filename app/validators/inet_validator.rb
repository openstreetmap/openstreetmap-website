# frozen_string_literal: true

# Validates that an inet/cidr column was given parseable input. ActiveRecord
# casts anything unparseable to nil, so the cast value alone can't tell a
# blank field from a typo; compare it against the raw input instead.
class InetValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    raw = record.read_attribute_before_type_cast(attribute)
    record.errors.add(attribute, options[:message] || :invalid) if raw.present? && value.nil?
  end
end
