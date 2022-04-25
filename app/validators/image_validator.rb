class ImageValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, " must be an image") unless value.image?
  end
end
