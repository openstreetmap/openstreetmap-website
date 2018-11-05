class TrailingWhitespaceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || I18n.t("validations.trailing_whitespace")) if value =~ /\s\z/
  end
end
