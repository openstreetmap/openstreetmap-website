require File.dirname(__FILE__) + '/../test_helper'

class ShortLinkTest < ActionController::IntegrationTest
  ##
  # test the short link with various parameters and ensure they're
  # kept in the redirect.
  def test_short_link_params
    assert_short_link_redirect('1N8H@P_5W')
    assert_short_link_redirect('euu4oTas==')
  end

  ##
  # utility method to test short links
  def assert_short_link_redirect(short_link)
    lon, lat, zoom = ShortLink::decode(short_link)

    # test without marker
    get '/go/' + short_link
    assert_redirected_to :controller => 'site', :action => 'index', :lat => lat, :lon => lon, :zoom => zoom

    # test with marker
    get '/go/' + short_link + "?m"
    assert_redirected_to :controller => 'site', :action => 'index', :mlat => lat, :mlon => lon, :zoom => zoom

    # test with layers and a marker
    get '/go/' + short_link + "?m&layers=B000FTF"
    assert_redirected_to :controller => 'site', :action => 'index', :mlat => lat, :mlon => lon, :zoom => zoom, :layers => "B000FTF"
    get '/go/' + short_link + "?layers=B000FTF&m"
    assert_redirected_to :controller => 'site', :action => 'index', :mlat => lat, :mlon => lon, :zoom => zoom, :layers => "B000FTF"

    # test with some random query parameters we haven't even implemented yet
    get '/go/' + short_link + "?foobar=yes"
    assert_redirected_to :controller => 'site', :action => 'index', :lat => lat, :lon => lon, :zoom => zoom, :foobar => "yes"
  end
end
