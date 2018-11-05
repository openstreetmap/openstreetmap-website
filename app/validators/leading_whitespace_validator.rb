class LeadingWhitespaceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || I18n.t("validations.leading_whitespace")) if value =~ /\A\s/
  end
end
