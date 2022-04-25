class WhitespaceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, options[:message] || I18n.t("validations.leading_whitespace")) if !options.fetch(:leading, true) && /\A\s/.match?(value)
    record.errors.add(attribute, options[:message] || I18n.t("validations.trailing_whitespace")) if !options.fetch(:trailing, true) && /\s\z/.match?(value)
  end
end
