require "date"

class DatetimeFormatValidator < ActiveModel::EachValidator
  # No need to pull in validates_timeless for just a simple validation.
  def validate_each(record, attribute, _value)
    # By this point in time, rails has already converted an invalid _value to
    # Nil.  With built in rails validation, there's no good way to say the
    # input is not a valid date.  Validate the user input.
    before_value = record.read_attribute_before_type_cast(attribute)
    return if before_value.is_a? Time

    Date.iso8601(before_value)
  rescue ArgumentError
    record.errors.add(attribute, options[:message] || I18n.t("validations.invalid_datetime_range"))
  end
end
