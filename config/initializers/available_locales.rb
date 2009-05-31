# Get loaded locales conveniently
# See http://rails-i18n.org/wiki/pages/i18n-available_locales
module I18n
  class << self
    def available_locales
      backend.available_locales
    end
  end
  module Backend
    class Simple
      def available_locales
        init_translations unless initialized?
        translations.keys
      end
    end
  end
end

