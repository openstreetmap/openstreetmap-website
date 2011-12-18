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

          @skip_syntax_deprecation = true
        end
      end
    end

    module Fallbacks
      def find_first_string_or_lambda_default(defaults)
        defaults.each_with_index { |default, ix| return ix if default && !default.is_a?(Symbol) }
        nil
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

I18n::Backend::Simple.include(I18n::Backend::Pluralization)
I18n::Backend::Simple.include(I18n::Backend::PluralizationFallback)
I18n.load_path << "#{Rails.root}/config/pluralizers.rb"

I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

Rails.configuration.after_initialize do
  I18n.reload!
end
