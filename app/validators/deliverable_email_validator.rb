# frozen_string_literal: true

# Validates that an email address is both RFC-compliant, using the
# validates_email_format_of gem, and will also be accepted by exim relays.
#
# Exim's default configuration rejects recipients on remote domains whose
# local part matches:
#
#   local_parts = ^[./|] : ^.*[@%!] : ^.*/\\.\\./
#
# Many such addresses are valid using RFC 5322, so otherwise the gem would accept them.

class DeliverableEmailValidator < ActiveModel::EachValidator
  INVALID_LOCAL_PART_CHARS = "@%!"
  INVALID_LOCAL_PART = %r{\A[./|]|/\.\./}

  def validate_each(record, attribute, value)
    errors = ValidatesEmailFormatOf.validate_email_format(value, options) || exim_errors(value)

    errors.each { |error| record.errors.add(attribute, error) }
  end

  private

  def exim_errors(value)
    local_part = value.rpartition("@").first
    errors = []

    errors << I18n.t("validations.email_characters", :characters => INVALID_LOCAL_PART_CHARS) if /[#{INVALID_LOCAL_PART_CHARS}]/o.match?(local_part)
    errors << I18n.t("validations.invalid_characters") if INVALID_LOCAL_PART.match?(local_part)

    errors
  end
end
