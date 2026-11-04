# frozen_string_literal: true

class CharactersValidator < ActiveModel::EachValidator
  INVALID_CHARS = "\x00-\x08\x0b-\x0c\x0e-\x1f\x7f\ufffe\uffff"
  INVALID_URL_CHARS = "/;.,?%#"

  # Exim applies additional character restrictions, beyond the RFC-compliant checks made
  # by the validates_email_format_of gem.
  #
  #   local_parts = ^[./|] : ^.*[@%!] : ^.*/\\.\\./
  INVALID_EMAIL_CHARS = "@%!"
  INVALID_EMAIL_LOCAL_PART = %r{\A[./|]|/\.\./}

  def validate_each(record, attribute, value)
    record.errors.add(attribute, options[:message] || I18n.t("validations.invalid_characters")) if /[#{INVALID_CHARS}]/o.match?(value)
    record.errors.add(attribute, options[:message] || I18n.t("validations.url_characters", :characters => INVALID_URL_CHARS)) if options[:url_safe] && /[#{INVALID_URL_CHARS}]/o.match?(value)
    validate_email(record, attribute, value) if options[:email_safe] && value
  end

  private

  def validate_email(record, attribute, value)
    local_part = value.rpartition("@").first

    record.errors.add(attribute, options[:message] || I18n.t("validations.email_characters", :characters => INVALID_EMAIL_CHARS)) if /[#{INVALID_EMAIL_CHARS}]/o.match?(local_part)
    record.errors.add(attribute, options[:message] || I18n.t("validations.invalid_characters")) if INVALID_EMAIL_LOCAL_PART.match?(local_part)
  end
end
