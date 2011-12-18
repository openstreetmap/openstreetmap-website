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

  module Locale
    class Fallbacks
      def compute(tags, include_defaults = true, exclude = [])
        result = Array(tags).collect do |tag|
          tags = I18n::Locale::Tag.tag(tag).self_and_parents.map! { |t| t.to_sym } - exclude
          tags.each { |_tag| tags += compute(@map[_tag], false, exclude + tags) if @map[_tag] }
          tags
        end.flatten
        result.push(*defaults) if include_defaults
        result.uniq.compact
      end
    end
  end
end

I18n::Backend::Simple.include(I18n::Backend::Pluralization)
I18n::Backend::Simple.include(I18n::Backend::PluralizationFallback)
I18n.load_path << "#{Rails.root}/config/pluralizers.rb"

I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

I18n.fallbacks.map("nb" => "no")
I18n.fallbacks.map("no" => "nb")

Rails.configuration.after_initialize do
  I18n.reload!
end
