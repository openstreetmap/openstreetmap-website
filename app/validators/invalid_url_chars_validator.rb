class InvalidUrlCharsValidator < ActiveModel::EachValidator
  INVALID_URL_CHARS = "/;.,?%#".freeze

  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || I18n.t("validations.invalid chars", :invalid_chars => INVALID_URL_CHARS)) if value =~ /[#{INVALID_URL_CHARS}]/
  end
end
