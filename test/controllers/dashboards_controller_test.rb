require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/dashboard", :method => :get },
      { :controller => "dashboards", :action => "show" }
    )
  end

  def test_show_no_friends
    user = create(:user)
    session_for(user)

    get dashboard_path
  end

  def test_show_with_friends
    user = create(:user, :home_lon => 1.1, :home_lat => 1.1)
    friend_user = create(:user, :home_lon => 1.2, :home_lat => 1.2)
    create(:friendship, :befriender => user, :befriendee => friend_user)
    create(:changeset, :user => friend_user)
    session_for(user)

    get dashboard_path

    # Friends should be visible as we're now logged in
    assert_select "div#friends-container" do
      assert_select "div" do
        assert_select "a[href='/user/#{ERB::Util.u(friend_user.display_name)}']", :count => 1
      end
    end
  end
end
