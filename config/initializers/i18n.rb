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

        super
      end
    end
  end
end

I18n::Backend::Simple.prepend(OpenStreetMap::I18n::NormaliseLocales)

I18n::Backend::Simple.include(I18n::Backend::PluralizationFallback)
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

I18n.enforce_available_locales = false

if Rails.env.test?
  I18n.exception_handler = proc do |exception|
    raise exception.to_exception
  end
end

Rails.configuration.after_initialize do
  require "i18n-js/listen"

  # This will only run in development.
  I18nJS.listen

  I18n.available_locales
end
