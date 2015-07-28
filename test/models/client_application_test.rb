require "test_helper"

class ClientApplicationTest < ActiveSupport::TestCase
  fixtures :client_applications

  def test_url_valid
    ok = ["http://example.com/test", "https://example.com/test"]
    bad = ["", "ftp://example.com/test", "myapp://somewhere"]

    ok.each do |url|
      app = client_applications(:normal_user_app).dup
      app.url = url
      assert app.valid?, "#{url} is invalid, when it should be"
    end

    bad.each do |url|
      app = client_applications(:normal_user_app)
      app.url = url
      assert !app.valid?, "#{url} is valid when it shouldn't be"
    end
  end

  def test_support_url_valid
    ok = ["", "http://example.com/test", "https://example.com/test"]
    bad = ["ftp://example.com/test", "myapp://somewhere", "gibberish"]

    ok.each do |url|
      app = client_applications(:normal_user_app)
      app.support_url = url
      assert app.valid?, "#{url} is invalid, when it should be"
    end

    bad.each do |url|
      app = client_applications(:normal_user_app)
      app.support_url = url
      assert !app.valid?, "#{url} is valid when it shouldn't be"
    end
  end

  def test_callback_url_valid
    ok = ["", "http://example.com/test", "https://example.com/test", "ftp://example.com/test", "myapp://somewhere"]
    bad = ["gibberish"]

    ok.each do |url|
      app = client_applications(:normal_user_app)
      app.callback_url = url
      assert app.valid?, "#{url} is invalid, when it should be"
    end

    bad.each do |url|
      app = client_applications(:normal_user_app)
      app.callback_url = url
      assert !app.valid?, "#{url} is valid when it shouldn't be"
    end
  end
end
