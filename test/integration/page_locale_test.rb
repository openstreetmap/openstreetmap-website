require "test_helper"

class PageLocaleTest < ActionDispatch::IntegrationTest
  def setup
    I18n.locale = "en"
    stub_hostip_requests
  end

  def teardown
    I18n.locale = "en"
  end

  def test_defaulting
    user = create(:user, :languages => [])

    post_via_redirect "/login", :username => user.email, :password => "test"

    get "/diary/new", {}
    assert_equal [], User.find(user.id).languages
    assert_select "html[lang=?]", "en"

    get "/diary/new", {}, { "HTTP_ACCEPT_LANGUAGE" => "fr, en" }
    assert_equal %w(fr en), User.find(user.id).languages
    assert_select "html[lang=?]", "fr"
  end

  def test_override
    user = create(:user, :languages => ["de"])

    get "/diary"
    assert_select "html[lang=?]", "en"

    get "/diary", :locale => "es"
    assert_select "html[lang=?]", "es"

    post_via_redirect "/login", :username => user.email, :password => "test"

    get "/diary"
    assert_select "html[lang=?]", "de"

    get "/diary", :locale => "fr"
    assert_select "html[lang=?]", "fr"
  end
end
