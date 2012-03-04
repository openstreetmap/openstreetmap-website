module I18n
  module Backend
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

I18n::Backend::Simple.include(I18n::Backend::PluralizationFallback)
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

I18n.fallbacks.map("no" => "nb")
