# coding: utf-8
require "test_helper"

class LanguageTest < ActiveSupport::TestCase
  fixtures :languages

  def test_language_count
    assert_equal 3, Language.count
  end

  def test_name
    assert_equal "English (English)", languages(:en).name
    assert_equal "German (Deutsch)", languages(:de).name
    assert_equal "Slovenian (slovenščina)", languages(:sl).name
  end

  def test_load
    assert_equal 3, Language.count
    assert_raise ActiveRecord::RecordNotFound do
      Language.find("zh")
    end

    Language.load("config/languages.yml")

    assert_equal 197, Language.count
    assert_not_nil Language.find("zh")
  end
end
