class CharactersValidator < ActiveModel::EachValidator
  INVALID_CHARS = "\x00-\x08\x0b-\x0c\x0e-\x1f\x7f\ufffe\uffff".freeze
  INVALID_URL_CHARS = "/;.,?%#".freeze

  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || I18n.t("validations.invalid_characters")) if /[#{INVALID_CHARS}]/.match?(value)

    if options[:url_safe]
      record.errors[attribute] << (options[:message] || I18n.t("validations.url_characters", :characters => INVALID_URL_CHARS)) if /[#{INVALID_URL_CHARS}]/.match?(value)
    end
  end
end
