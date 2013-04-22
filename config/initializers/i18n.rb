module I18n
  module Backend
    module PluralizationFallback
      def pluralize(locale, entry, count)
        super
      rescue InvalidPluralizationData => ex
        raise ex unless ex.entry.has_key?(:other)
        ex.entry[:other]
      end
    end
  end

  module JS
    class << self
      def make_ordered(unordered)
        ordered = ActiveSupport::OrderedHash.new

        unordered.keys.sort { |a,b| a.to_s <=> b.to_s }.each do |key|
          value = unordered[key]

          if value.is_a?(Hash)
            ordered[key] = make_ordered(value)
          else
            ordered[key] = value
          end
        end

        ordered
      end

      def filtered_translations_with_order
        make_ordered(filtered_translations_without_order)
      end

      alias_method_chain :filtered_translations, :order
    end
  end
end

I18n::Backend::Simple.include(I18n::Backend::PluralizationFallback)
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

I18n.fallbacks.map("no" => "nb")

Rails.configuration.after_initialize do |app|
  I18n.available_locales
end
