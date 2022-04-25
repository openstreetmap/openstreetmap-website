##
# validation method to be included like any other validations methods
# in the models definitions. this one checks that the named attribute
# is a valid UTF-8 format string.
class Utf8Validator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, " is invalid UTF-8") unless UTF8.valid? value
  end
end
