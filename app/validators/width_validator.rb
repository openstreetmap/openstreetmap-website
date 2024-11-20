class WidthValidator < ActiveModel::Validations::LengthValidator
  module WidthAsLength
    def length
      Unicode::DisplayWidth.of(to_s)
    end
  end

  def validate_each(record, attribute, value)
    super(record, attribute, value.extend(WidthAsLength))
  end
end
