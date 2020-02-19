require "date"

class DatetimeFormatValidator < ActiveModel::EachValidator
  # Just basic format yyyy-mm-ddThh:mm
  # FORMAT = "\d\d\d\d-\d\d-\d\dT\d\d:\d\d".freeze

  def validate_each(record, attribute, _value)
    # Validate the format.
    # Not sure if this is worth doing.  It's probably faster, but unlikely to happen.
    # record.errors[attribute] << (options[:message] || I18n.t("validations.invalid_datetime_format")) if value !~ /#{FORMAT}/

    # Validate the range.
    before_value = record.read_attribute_before_type_cast(attribute)
    Date.iso8601(before_value)
  rescue ArgumentError
    record.errors[attribute] << (options[:message] || I18n.t("validations.invalid_datetime_range"))
  end
end
