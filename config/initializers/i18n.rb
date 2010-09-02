module I18n
  module Backend
    class Simple
      module Implementation
        protected
        alias_method :old_init_translations, :init_translations
      
        def init_translations
          old_init_translations

          store_translations(:nb, translations[:no])
          translations[:no] = translations[:nb]

          friendly = translate('en', 'time.formats.friendly')

          available_locales.each do |locale|
            unless lookup(locale, 'time.formats.friendly')
              store_translations(locale, :time => { :formats => { :friendly => friendly } })
            end
          end

          @skip_syntax_deprecation = true
        end
      end
    end

    module PluralizationFallback
      def pluralize(locale, entry, count)
        super
      rescue InvalidPluralizationData => ex
        raise ex unless ex.entry.has_key?(:other)
        ex.entry[:other]
      end
    end
  end
end

I18n::Backend::Simple.send(:include, I18n::Backend::Pluralization)
I18n::Backend::Simple.send(:include, I18n::Backend::PluralizationFallback)
I18n.load_path << RAILS_ROOT + "/config/pluralizers.rb"

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
