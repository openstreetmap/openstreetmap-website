class NormalizedUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    relation = if options.fetch(:case_sensitive, true)
                 record.class.where("NORMALIZE(#{attribute}, NFKC) = NORMALIZE(?, NFKC)", value)
               else
                 record.class.where("LOWER(NORMALIZE(#{attribute}, NFKC)) = LOWER(NORMALIZE(?, NFKC))", value)
               end

    relation = relation.where.not(record.class.primary_key => [record.id_in_database]) if record.persisted?

    if relation.exists?
      error_options = options.except(:case_sensitive)
      error_options[:value] = value

      record.errors.add(attribute, :taken, **error_options)
    end
  end
end
