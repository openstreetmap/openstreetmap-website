require 'test_helper'

class I18nTest < ActiveSupport::TestCase
  I18n.available_locales.each do |locale|
    define_method("test_#{locale.to_s.underscore}".to_sym) do
      # plural_keys = plural_keys(locale)

      translation_keys.each do |key|
        variables = []

        default_value = I18n.t(key, :locale => I18n.default_locale)

        if default_value.is_a?(Hash)
          variables.push("count")

          default_value.each do |_subkey, subvalue|
            subvalue.scan(/%\{(\w+)\}/) do
              variables.push($1)
            end
          end
        else
          default_value.scan(/%\{(\w+)\}/) do
            variables.push($1)
          end
        end

        if key =~ /^(active(model|record)\.)?errors\./
          variables.push("attribute")
        end

        value = I18n.t(key, :locale => locale, :fallback => true)

        if value.is_a?(Hash)
          value.each do |subkey, subvalue|
            # assert plural_keys.include?(subkey), "#{key}.#{subkey} is not a valid plural key"

            unless subvalue.nil?
              subvalue.scan(/%\{(\w+)\}/) do
                assert variables.include?($1), "#{key}.#{subkey} uses unknown interpolation variable #{$1}"
              end
            end
          end
        else
          assert value.is_a?(String), "#{key} is not a string"

          value.scan(/%\{(\w+)\}/) do
            assert variables.include?($1), "#{key} uses unknown interpolation variable #{$1}"
          end
        end
      end

      assert %w(ltr rtl).include?(I18n.t("html.dir", :locale => locale)), "html.dir must be ltr or rtl"
    end
  end

  private

  def translation_keys(scope = nil)
    plural_keys = plural_keys(I18n.default_locale)

    I18n.t(scope || ".", :locale => I18n.default_locale).map do |key, value|
      scoped_key = scope ? "#{scope}.#{key}" : key

      if value.is_a?(Hash)
        if value.keys - plural_keys == []
          scoped_key
        else
          translation_keys(scoped_key)
        end
      elsif value.is_a?(String)
        scoped_key
      end
    end.flatten
  end

  def plural_keys(locale)
    I18n.t("i18n.plural.keys", :locale => locale, :raise => true) + [:zero]
  rescue I18n::MissingTranslationData
    [:zero, :one, :other]
  end
end
