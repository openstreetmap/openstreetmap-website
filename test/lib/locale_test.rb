require "test_helper"

class LocaleTest < ActiveSupport::TestCase
  EN = Locale.new("en")
  EN_GB = Locale.new("en", nil, "GB")
  FR = Locale.new("fr")
  ZH_HANS = Locale.new("zh", "Hans")
  ZH_HANT_TW = Locale.new("zh", "Hant", "TW")
  ZH_YUE = Locale.new("zh-yue")
  BE_TARASK = Locale.new("be", nil, nil, "tarask")

  def test_tag
    assert_equal EN, Locale.tag("en")
    assert_equal EN_GB, Locale.tag("en-GB")
    assert_equal FR, Locale.tag("fr")
    assert_equal ZH_HANS, Locale.tag("zh-Hans")
    assert_equal ZH_HANT_TW, Locale.tag("zh-Hant-TW")
    assert_equal ZH_YUE, Locale.tag("zh-yue")
    assert_equal BE_TARASK, Locale.tag("be-tarask")
  end

  def test_language
    assert_equal EN.language, Locale.tag("en").language
    assert_equal EN_GB.language, Locale.tag("en-GB").language
    assert_equal FR.language, Locale.tag("fr").language
    assert_equal ZH_HANS.language, Locale.tag("zh-Hans").language
    assert_equal ZH_HANT_TW.language, Locale.tag("zh-Hant-TW").language
    assert_equal ZH_YUE.language, Locale.tag("zh-yue").language
    assert_equal ZH_YUE.language, Locale.tag("zh-YUE").language
    assert_equal BE_TARASK.language, Locale.tag("be-tarask").language
    assert_equal BE_TARASK.language, Locale.tag("be-Tarask").language
  end

  def test_script
    assert_equal EN.script, Locale.tag("en").script
    assert_equal EN_GB.script, Locale.tag("en-GB").script
    assert_equal FR.script, Locale.tag("fr").script
    assert_equal ZH_HANS.script, Locale.tag("zh-Hans").script
    assert_equal ZH_HANT_TW.script, Locale.tag("zh-Hant-TW").script
    assert_equal ZH_YUE.script, Locale.tag("zh-yue").script
    assert_equal ZH_YUE.script, Locale.tag("zh-YUE").script
    assert_equal BE_TARASK.script, Locale.tag("be-tarask").script
    assert_equal BE_TARASK.script, Locale.tag("be-Tarask").script
  end

  def test_region
    assert_equal EN.region, Locale.tag("en").region
    assert_equal EN_GB.region, Locale.tag("en-GB").region
    assert_equal FR.region, Locale.tag("fr").region
    assert_equal ZH_HANS.region, Locale.tag("zh-Hans").region
    assert_equal ZH_HANT_TW.region, Locale.tag("zh-Hant-TW").region
    assert_equal ZH_YUE.region, Locale.tag("zh-yue").region
    assert_equal ZH_YUE.region, Locale.tag("zh-YUE").region
    assert_equal BE_TARASK.region, Locale.tag("be-tarask").region
    assert_equal BE_TARASK.region, Locale.tag("be-Tarask").region
  end

  def test_variant
    assert_equal EN.variant, Locale.tag("en").variant
    assert_equal EN_GB.variant, Locale.tag("en-GB").variant
    assert_equal FR.variant, Locale.tag("fr").variant
    assert_equal ZH_HANS.variant, Locale.tag("zh-Hans").variant
    assert_equal ZH_HANT_TW.variant, Locale.tag("zh-Hant-TW").variant
    assert_equal ZH_YUE.variant, Locale.tag("zh-yue").variant
    assert_equal ZH_YUE.variant, Locale.tag("zh-YUE").variant
    assert_equal BE_TARASK.variant, Locale.tag("be-tarask").variant
    assert_equal BE_TARASK.variant, Locale.tag("be-Tarask").variant
  end

  def test_list
    assert_equal [], Locale.list
    assert_equal [EN], Locale.list("en")
    assert_equal [EN, ZH_YUE, ZH_HANT_TW], Locale.list("en", "zh-yue", "zh-Hant-TW")
    assert_equal [ZH_YUE, ZH_HANT_TW], Locale.list("en;de", "zh-yue", "zh-Hant-TW")
    assert_equal [ZH_YUE, ZH_HANT_TW], Locale.list(["en;de", "zh-yue", "zh-Hant-TW"])
  end

  def test_default
    assert_equal EN, Locale.default
  end

  def test_available
    assert_equal I18n.available_locales.count, Locale.available.count
  end

  def test_preferred
    assert_equal "en-GB", Locale.available.preferred(Locale.list("en-GB", "en")).to_s
    assert_equal "en", Locale.available.preferred(Locale.list("en")).to_s
    assert_equal "fr", Locale.available.preferred(Locale.list("fr-GB", "fr", "en")).to_s
    assert_equal "fr", Locale.available.preferred(Locale.list("fr", "en")).to_s
    assert_equal "de", Locale.available.preferred(Locale.list("zh-Hant", "de")).to_s
    assert_equal "zh-TW", Locale.available.preferred(Locale.list("zh-Hant-TW", "de")).to_s
    assert_equal "zh-TW", Locale.available.preferred(Locale.list("zh-TW", "de")).to_s
    assert_equal "zh-HK", Locale.available.preferred(Locale.list("yue", "zh-HK", "de")).to_s
    assert_equal "zh-yue", Locale.available. preferred(Locale.list("yue", "zh-yue", "zh-HK", "de")).to_s
    assert_equal "zh-yue", Locale.available. preferred(Locale.list("yue", "zh-YUE", "zh-HK", "de")).to_s
    assert_equal "en", Locale.available.preferred(Locale.list("yue")).to_s
  end
end
