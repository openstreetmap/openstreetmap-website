require "test_helper"

class I18nTest < ActiveSupport::TestCase
  I18n.available_locales.each do |locale|
    test locale.to_s do
      without_i18n_exceptions do
        # plural_keys = plural_keys(locale)

        translation_keys.each do |key|
          variables = []

          default_value = I18n.t(key, :locale => I18n.default_locale)

          if default_value.is_a?(Hash)
            variables.push("count")

            default_value.each_value do |subvalue|
              subvalue.scan(/%\{(\w+)\}/) do
                variables.push(Regexp.last_match(1))
              end
            end
          else
            default_value.scan(/%\{(\w+)\}/) do
              variables.push(Regexp.last_match(1))
            end
          end

          variables.push("attribute") if key =~ /^(active(model|record)\.)?errors\./

          value = I18n.t(key, :locale => locale, :fallback => true)

          if value.is_a?(Hash)
            value.each do |subkey, subvalue|
              # assert plural_keys.include?(subkey), "#{key}.#{subkey} is not a valid plural key"

              next if subvalue.nil?

              subvalue.scan(/%\{(\w+)\}/) do
                assert_includes variables, Regexp.last_match(1), "#{key}.#{subkey} uses unknown interpolation variable #{Regexp.last_match(1)}"
              end
            end

            assert_includes value, :other, "#{key}.other plural key missing"
          else
            assert_kind_of String, value, "#{key} is not a string"

            value.scan(/%\{(\w+)\}/) do
              assert_includes variables, Regexp.last_match(1), "#{key} uses unknown interpolation variable #{Regexp.last_match(1)}"
            end
          end
        end

        assert_includes %w[ltr rtl], I18n.t("html.dir", :locale => locale), "html.dir must be ltr or rtl"
      end
    end
  end

  Rails.root.glob("config/locales/*.yml").each do |filename|
    lang = File.basename(filename, ".yml")
    test "#{lang} for raw html" do
      yml = YAML.load_file(filename)
      assert_nothing_raised do
        check_values_for_raw_html(yml)
      end
    end
  end

  def test_en_for_nil_values
    en = YAML.load_file(Rails.root.join("config/locales/en.yml"))
    assert_nothing_raised do
      check_values_for_nil(en)
    end
  end

  # We should avoid using the key `zero:` in English, since that key
  # is used for "numbers ending in zero" in other languages.
  def test_en_for_zero_key
    en = YAML.load_file(Rails.root.join("config/locales/en.yml"))
    assert_nothing_raised do
      check_keys_for_zero(en)
    end
  end

  private

  def translation_keys(scope = nil)
    plural_keys = plural_keys(I18n.default_locale)

    I18n.t(scope || ".", :locale => I18n.default_locale).map do |key, value|
      scoped_key = scope ? "#{scope}.#{key}" : key

      case value
      when Hash
        if value.keys - plural_keys == []
          scoped_key
        else
          translation_keys(scoped_key)
        end
      when String
        scoped_key
      end
    end.flatten
  end

  def plural_keys(locale)
    I18n.t("i18n.plural.keys", :locale => locale, :raise => true) + [:zero]
  rescue I18n::MissingTranslationData
    [:zero, :one, :other]
  end

  def check_values_for_raw_html(hash)
    hash.each_pair do |k, v|
      if v.is_a? Hash
        check_values_for_raw_html(v)
      else
        next unless k.to_s.end_with?("_html")
        raise "Avoid using raw html in '#{k}: #{v}'" if v.include? "<"
      end
    end
  end

  def check_values_for_nil(hash)
    hash.each_pair do |k, v|
      if v.is_a? Hash
        check_values_for_nil(v)
      else
        raise "Avoid nil values in '#{k}: nil'" if v.nil?
      end
    end
  end

  def check_keys_for_zero(hash)
    hash.each_pair do |k, v|
      if v.is_a? Hash
        check_keys_for_zero(v)
      else
        raise "Avoid using 'zero' key in '#{k}: #{v}'" if k.to_s == "zero"
      end
    end
  end
end
