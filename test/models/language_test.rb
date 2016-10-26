# coding: utf-8
require "test_helper"

class LanguageTest < ActiveSupport::TestCase
  def test_name
    create(:language, :code => "sl", :english_name => "Slovenian", :native_name => "slovenščina")
    assert_equal "Slovenian (slovenščina)", Language.find("sl").name
  end

  def test_load
    assert_equal 0, Language.count
    assert_raise ActiveRecord::RecordNotFound do
      Language.find("zh")
    end

    Language.load("config/languages.yml")

    assert_equal 197, Language.count
    assert_not_nil Language.find("zh")
  end
end
