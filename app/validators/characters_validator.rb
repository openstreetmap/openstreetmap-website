class CharactersValidator < ActiveModel::EachValidator
  INVALID_CHARS = "\x00-\x08\x0b-\x0c\x0e-\x1f\x7f\ufffe\uffff".freeze
  INVALID_URL_CHARS = "/;.,?%#".freeze

  def validate_each(record, attribute, value)
    record.errors.add(attribute, options[:message] || I18n.t("validations.invalid_characters")) if /[#{INVALID_CHARS}]/o.match?(value)
    record.errors.add(attribute, options[:message] || I18n.t("validations.url_characters", :characters => INVALID_URL_CHARS)) if options[:url_safe] && /[#{INVALID_URL_CHARS}]/o.match?(value)
  end
end
