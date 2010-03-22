require 'globalize/i18n/missing_translations_log_handler'

I18n.missing_translations_logger = Logger.new("#{RAILS_ROOT}/log/missing_translations.log")
I18n.exception_handler = :missing_translations_log_handler
I18n.load_path += Dir[ File.join(RAILS_ROOT, 'config', 'legales', '*.yml') ]

module I18n
  module Backend
    class Simple
      protected
      alias_method :old_init_translations, :init_translations
      
      def init_translations
        old_init_translations

        merge_translations(:nb, translations[:no])
        translations[:no] = translations[:nb]

        friendly = translate('en', 'time.formats.friendly')

        available_locales.each do |locale|
          time_formats = I18n.t('time.formats', :locale => locale)

          unless time_formats.has_key?(:friendly)
            store_translations(locale, :time => { :formats => { :friendly => friendly } })
          end
        end
      end
    end
  end
end
