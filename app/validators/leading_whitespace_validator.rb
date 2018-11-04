class LeadingWhitespaceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value =~ /\A\s/
      record.errors[attribute] << (options[:message] || I18n.t("validations.leading whitespace"))
    end
  end
end