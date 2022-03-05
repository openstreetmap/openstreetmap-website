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
    create(:oauth_access_grant, :resource_owner_id => user.id, :application => application1)
    create(:oauth_access_token, :resource_owner_id => user.id, :application => application1)
    application2 = create(:oauth_application)
    create(:oauth_access_grant, :resource_owner_id => user.id, :application => application2)
    create(:oauth_access_token, :resource_owner_id => user.id, :application => application2)
    create(:oauth_application)

    get oauth_authorized_applications_path
    assert_response :redirect
    assert_redirected_to login_path(:referer => oauth_authorized_applications_path)

    session_for(user)

    get oauth_authorized_applications_path
    assert_response :success
    assert_template "oauth2_authorized_applications/index"
    assert_select "tbody tr", 2
  end

  def test_destroy
    user = create(:user)
    application1 = create(:oauth_application)
    create(:oauth_access_grant, :resource_owner_id => user.id, :application => application1)
    create(:oauth_access_token, :resource_owner_id => user.id, :application => application1)
    application2 = create(:oauth_application)
    create(:oauth_access_grant, :resource_owner_id => user.id, :application => application2)
    create(:oauth_access_token, :resource_owner_id => user.id, :application => application2)
    create(:oauth_application)

    delete oauth_authorized_application_path(:id => application1.id)
    assert_response :forbidden

    session_for(user)

    delete oauth_authorized_application_path(:id => application1.id)
    assert_response :redirect
    assert_redirected_to oauth_authorized_applications_path

    get oauth_authorized_applications_path
    assert_response :success
    assert_template "oauth2_authorized_applications/index"
    assert_select "tbody tr", 1
  end
end
