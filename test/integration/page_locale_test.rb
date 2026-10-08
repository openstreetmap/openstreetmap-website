# frozen_string_literal: true

require "test_helper"

class PageLocaleTest < ActionDispatch::IntegrationTest
  def test_defaulting
    I18n.with_locale "en" do
      user = create(:user, :languages => [])

      session_for(user)

      get "/diary/new"
      assert_empty User.find(user.id).languages
      assert_select "html[lang=?]", "en"

      get "/diary/new", :headers => { "Accept-Language" => "fr, en" }
      assert_equal %w[fr en], User.find(user.id).languages
      assert_select "html[lang=?]", "fr"
    end
  end

  def test_override
    I18n.with_locale "en" do
      user = create(:user, :languages => ["de"])

      get "/diary"
      assert_select "html[lang=?]", "en"

      get "/diary", :params => { :locale => "es" }
      assert_select "html[lang=?]", "es"

      session_for(user)

      get "/diary"
      assert_select "html[lang=?]", "de"

      get "/diary", :params => { :locale => "fr" }
      assert_select "html[lang=?]", "fr"
    end
  end
end
