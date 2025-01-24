require "test_helper"

class Oauth2AuthorizedApplicationsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/oauth2/authorized_applications", :method => :get },
      { :controller => "oauth2_authorized_applications", :action => "index" }
    )
    assert_routing(
      { :path => "/oauth2/authorized_applications/1", :method => :delete },
      { :controller => "oauth2_authorized_applications", :action => "destroy", :id => "1" }
    )
  end

  def test_index
    user = create(:user)
    application1 = create(:oauth_application)
    create(:oauth_access_grant, :user => user, :application => application1)
    create(:oauth_access_token, :user => user, :application => application1)
    application2 = create(:oauth_application)
    create(:oauth_access_grant, :user => user, :application => application2)
    create(:oauth_access_token, :user => user, :application => application2)
    create(:oauth_application)

    get oauth_authorized_applications_path
    assert_redirected_to login_path(:referer => oauth_authorized_applications_path)

    session_for(user)

    get oauth_authorized_applications_path
    assert_response :success
    assert_template "oauth2_authorized_applications/index"
    assert_select "tbody tr", 2
  end

  def test_index_scopes
    user = create(:user)
    application1 = create(:oauth_application, :scopes => %w[read_prefs write_prefs write_diary read_gpx write_gpx])
    create(:oauth_access_grant, :user => user, :application => application1, :scopes => %w[read_prefs write_prefs])
    create(:oauth_access_token, :user => user, :application => application1, :scopes => %w[read_prefs write_prefs])
    create(:oauth_access_grant, :user => user, :application => application1, :scopes => %w[read_prefs write_diary])
    create(:oauth_access_token, :user => user, :application => application1, :scopes => %w[read_prefs write_diary])

    get oauth_authorized_applications_path
    assert_redirected_to login_path(:referer => oauth_authorized_applications_path)

    session_for(user)

    get oauth_authorized_applications_path
    assert_response :success
    assert_template "oauth2_authorized_applications/index"
    assert_select "tbody tr", 1
    assert_select "tbody tr td ul" do
      assert_select "li", :count => 3
      assert_select "li", :text => "Read user preferences"
      assert_select "li", :text => "Modify user preferences"
      assert_select "li", :text => "Create diary entries and comments"
    end
  end

  def test_destroy
    user = create(:user)
    application1 = create(:oauth_application)
    create(:oauth_access_grant, :user => user, :application => application1)
    create(:oauth_access_token, :user => user, :application => application1)
    application2 = create(:oauth_application)
    create(:oauth_access_grant, :user => user, :application => application2)
    create(:oauth_access_token, :user => user, :application => application2)
    create(:oauth_application)

    delete oauth_authorized_application_path(:id => application1.id)
    assert_response :forbidden

    session_for(user)

    delete oauth_authorized_application_path(:id => application1.id)
    assert_redirected_to oauth_authorized_applications_path

    get oauth_authorized_applications_path
    assert_response :success
    assert_template "oauth2_authorized_applications/index"
    assert_select "tbody tr", 1
  end
end
