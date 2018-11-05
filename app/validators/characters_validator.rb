class CharactersValidator < ActiveModel::EachValidator
  INVALID_CHARS = "\x00-\x08\x0b-\x0c\x0e-\x1f\x7f\ufffe\uffff".freeze
  INVALID_URL_CHARS = "/;.,?%#".freeze

  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || I18n.t("validations.invalid_chars")) if value =~ /[#{INVALID_CHARS}]/

    if options[:url_safe]
      record.errors[attribute] << (options[:message] || I18n.t("validations.invalid_url_chars", :invalid_url_chars => INVALID_URL_CHARS)) if value =~ /[#{INVALID_URL_CHARS}]/
    end
  end
end
