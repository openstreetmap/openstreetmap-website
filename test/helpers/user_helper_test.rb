require "test_helper"

class UserHelperTest < ActionView::TestCase
  include ERB::Util

  def test_user_image
    user = create(:user)
    gravatar_user = create(:user, :image_use_gravatar => true)

    image = user_image(user)
    assert_match %r{^<img class="user_image" .* src="/assets/users/images/large-.*" />$}, image

    image = user_image(user, :class => "foo")
    assert_match %r{^<img class="foo" .* src="/assets/users/images/large-.*" />$}, image

    image = user_image(gravatar_user)
    assert_match %r{^<img class="user_image" .* src="http://www.gravatar.com/avatar/.*" />$}, image

    image = user_image(gravatar_user, :class => "foo")
    assert_match %r{^<img class="foo" .* src="http://www.gravatar.com/avatar/.*" />$}, image
  end

  def test_user_thumbnail
    user = create(:user)
    gravatar_user = create(:user, :image_use_gravatar => true)

    image = user_thumbnail(user)
    assert_match %r{^<img class="user_thumbnail" .* src="/assets/users/images/small-.*" />$}, image

    image = user_thumbnail(user, :class => "foo")
    assert_match %r{^<img class="foo" .* src="/assets/users/images/small-.*" />$}, image

    image = user_thumbnail(gravatar_user)
    assert_match %r{^<img class="user_thumbnail" .* src="http://www.gravatar.com/avatar/.*" />$}, image

    image = user_thumbnail(gravatar_user, :class => "foo")
    assert_match %r{^<img class="foo" .* src="http://www.gravatar.com/avatar/.*" />$}, image
  end

  def test_user_thumbnail_tiny
    user = create(:user)
    gravatar_user = create(:user, :image_use_gravatar => true)

    image = user_thumbnail_tiny(user)
    assert_match %r{^<img class="user_thumbnail_tiny" .* src="/assets/users/images/small-.*" />$}, image

    image = user_thumbnail_tiny(user, :class => "foo")
    assert_match %r{^<img class="foo" .* src="/assets/users/images/small-.*" />$}, image

    image = user_thumbnail_tiny(gravatar_user)
    assert_match %r{^<img class="user_thumbnail_tiny" .* src="http://www.gravatar.com/avatar/.*" />$}, image

    image = user_thumbnail_tiny(gravatar_user, :class => "foo")
    assert_match %r{^<img class="foo" .* src="http://www.gravatar.com/avatar/.*" />$}, image
  end

  def test_user_image_url
    user = create(:user, :image_file_name => "test.jpg", :image_fingerprint => "d41d8cd98f00b204e9800998ecf8427e")
    gravatar_user = create(:user, :image_use_gravatar => true)

    url = user_image_url(user)
    assert_match %r{^/attachments/users/images/\d{3}/\d{3}/\d{3}/large/d41d8cd98f00b204e9800998ecf8427e.jpg$}, url

    url = user_image_url(gravatar_user)
    assert_match %r{^http://www.gravatar.com/avatar/}, url
  end

  def test_openid_logo
    logo = openid_logo
    assert_match %r{^<img .* class="openid_logo" src="/images/openid_small.png" />$}, logo
  end

  def test_auth_button
    button = auth_button("google", "google")
    assert_equal button, "<a class=\"auth_button\" title=\"Login with Google\" href=\"/auth/google\"><img alt=\"Login with a Google OpenID\" src=\"/images/google.png\" /></a>"

    button = auth_button("yahoo", "openid", :openid_url => "yahoo.com")
    assert_equal button, "<a class=\"auth_button\" title=\"Login with Yahoo\" href=\"/auth/openid?openid_url=yahoo\.com\"><img alt=\"Login with a Yahoo OpenID\" src=\"/images/yahoo.png\" /></a>"
  end

  private

  def request
    controller.request
  end
end
