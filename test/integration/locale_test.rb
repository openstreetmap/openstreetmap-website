require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  fixtures :users

  def test_defaulting
    user = users(:second_public_user)

    post_via_redirect "/login", :username => user.email, :password => "test"

    get "/diary/new", {}
    assert_equal [], User.find(user.id).languages
    assert_select "html[lang=?]", "en"

    get "/diary/new", {},  { "HTTP_ACCEPT_LANGUAGE" => "fr, en" }
    assert_equal %w(fr en), User.find(user.id).languages
    assert_select "html[lang=?]", "fr"
  end

  def test_override
    user = users(:german_user)

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
