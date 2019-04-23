module I18n
  module Backend
    module PluralizationFallback
      def pluralize(locale, entry, count)
        super
      rescue InvalidPluralizationData => e
        raise e unless e.entry.key?(:other)

        e.entry[:other]
      end
    end
  end
end

module OpenStreetMap
  module I18n
    module NormaliseLocales
      def store_translations(locale, data, options = {})
        locale = ::I18n::Locale::Tag::Rfc4646.tag(locale).to_s

        super(locale, data, options)
      end
    end

    module ValidateLocales
      def default_fallbacks
        super.select do |locale|
          ::I18n.available_locales.include?(locale)
        end
      end
    end
  end
end

I18n::Backend::Simple.prepend(OpenStreetMap::I18n::NormaliseLocales)
I18n::JS::FallbackLocales.prepend(OpenStreetMap::I18n::ValidateLocales)

I18n::Backend::Simple.include(I18n::Backend::PluralizationFallback)
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

I18n.fallbacks.map("no" => "nb")

I18n.enforce_available_locales = false

Rails.configuration.after_initialize do
  I18n.available_locales
end
