class TrailingWhitespaceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value =~ /\s\z/
      record.errors[attribute] << (options[:message] || I18n.t("validations.trailing whitespace"))
    end
  end
end