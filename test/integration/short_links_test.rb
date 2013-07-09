require File.dirname(__FILE__) + '/../test_helper'

class ShortLinksTest < ActionController::IntegrationTest
  ##
  # test the short link with various parameters and ensure they're
  # kept in the redirect.
  def test_short_link_params
    assert_short_link_redirect('1N8H@P_5W')
    assert_short_link_redirect(ShortLink::encode(-0.107846, 51.50771, 18))
  end

  ##
  # utility method to test short links
  def assert_short_link_redirect(short_link)
    lon, lat, zoom = ShortLink::decode(short_link)

    # test without marker
    get '/go/' + short_link
    assert_redirected_to :controller => 'site', :action => 'index', :lat => lat.to_s, :lon => lon.to_s, :zoom => zoom.to_s

    # test with marker
    get '/go/' + short_link + "?m"
    assert_redirected_to :controller => 'site', :action => 'index', :mlat => lat.to_s, :mlon => lon.to_s, :zoom => zoom.to_s

    # test with layers and a marker
    get '/go/' + short_link + "?m&layers=B000FTF"
    assert_redirected_to :controller => 'site', :action => 'index', :mlat => lat.to_s, :mlon => lon.to_s, :zoom => zoom.to_s, :layers => "B000FTF"
    get '/go/' + short_link + "?layers=B000FTF&m"
    assert_redirected_to :controller => 'site', :action => 'index', :mlat => lat.to_s, :mlon => lon.to_s, :zoom => zoom.to_s, :layers => "B000FTF"

    # test with some random query parameters we haven't even implemented yet
    get '/go/' + short_link + "?foobar=yes"
    assert_redirected_to :controller => 'site', :action => 'index', :lat => lat.to_s, :lon => lon.to_s, :zoom => zoom.to_s, :foobar => "yes"
  end
end
