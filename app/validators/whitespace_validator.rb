class WhitespaceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless options.fetch(:leading, true)
      record.errors[attribute] << (options[:message] || I18n.t("validations.leading_whitespace")) if /\A\s/.match?(value)
    end

    unless options.fetch(:trailing, true)
      record.errors[attribute] << (options[:message] || I18n.t("validations.trailing_whitespace")) if /\s\z/.match?(value)
    end
  end
end
