class InvalidCharsValidator < ActiveModel::EachValidator
  INVALID_CHARS = "\x00-\x08\x0b-\x0c\x0e-\x1f\x7f\ufffe\uffff".freeze

  def validate_each(record, attribute, value)
    if value =~ /[#{INVALID_CHARS}]/
      record.errors[attribute] << (options[:message] || "contains invalid chars")
    end
  end
end