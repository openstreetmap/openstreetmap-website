require "test_helper"

class ClientApplicationTest < ActiveSupport::TestCase
  def test_url_valid
    ok = ["http://example.com/test", "https://example.com/test"]
    bad = ["", "ftp://example.com/test", "myapp://somewhere"]

    ok.each do |url|
      app = build(:client_application)
      app.url = url
      assert app.valid?, "#{url} is invalid, when it should be"
    end

    bad.each do |url|
      app = build(:client_application)
      app.url = url
      assert_not app.valid?, "#{url} is valid when it shouldn't be"
    end
  end

  def test_support_url_valid
    ok = ["", "http://example.com/test", "https://example.com/test"]
    bad = ["ftp://example.com/test", "myapp://somewhere", "gibberish"]

    ok.each do |url|
      app = build(:client_application)
      app.support_url = url
      assert app.valid?, "#{url} is invalid, when it should be"
    end

    bad.each do |url|
      app = build(:client_application)
      app.support_url = url
      assert_not app.valid?, "#{url} is valid when it shouldn't be"
    end
  end

  def test_callback_url_valid
    ok = ["", "http://example.com/test", "https://example.com/test", "ftp://example.com/test", "myapp://somewhere"]
    bad = ["gibberish"]

    ok.each do |url|
      app = build(:client_application)
      app.callback_url = url
      assert app.valid?, "#{url} is invalid, when it should be"
    end

    bad.each do |url|
      app = build(:client_application)
      app.callback_url = url
      assert_not app.valid?, "#{url} is valid when it shouldn't be"
    end
  end
end
