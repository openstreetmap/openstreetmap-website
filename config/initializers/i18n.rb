module I18n
  module Backend
    module PluralizationFallback
      def pluralize(locale, entry, count)
        super
      rescue InvalidPluralizationData => ex
        raise ex unless ex.entry.key?(:other)
        ex.entry[:other]
      end
    end

    class Simple
      def store_translations_with_normalisation(locale, data, options = {})
        locale = I18n::Locale::Tag::Rfc4646.tag(locale).to_s

        store_translations_without_normalisation(locale, data, options)
      end

      alias_method_chain :store_translations, :normalisation
    end
  end

  module JS
    class FallbackLocales
      def default_fallbacks_with_validation
        default_fallbacks_without_validation.select do |locale|
          ::I18n.available_locales.include?(locale)
        end
      end

      alias_method_chain :default_fallbacks, :validation
    end
  end
end

I18n::Backend::Simple.include(I18n::Backend::PluralizationFallback)
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

I18n.fallbacks.map("no" => "nb")

I18n.enforce_available_locales = false

Rails.configuration.after_initialize do
  I18n.available_locales
end
