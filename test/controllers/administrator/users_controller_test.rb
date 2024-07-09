require "test_helper"

module Administrator
  class UsersControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/users", :method => :get },
        { :controller => "administrator/users", :action => "index" }
      )
      assert_routing(
        { :path => "/users", :method => :post },
        { :controller => "administrator/users", :action => "index" }
      )
      assert_routing(
        { :path => "/users/status", :method => :get },
        { :controller => "administrator/users", :action => "index", :status => "status" }
      )
      assert_routing(
        { :path => "/users/status", :method => :post },
        { :controller => "administrator/users", :action => "index", :status => "status" }
      )
    end

    def test_index_get
      user = create(:user)
      moderator_user = create(:moderator_user)
      administrator_user = create(:administrator_user)
      _suspended_user = create(:user, :suspended)
      _ip_user = create(:user, :creation_ip => "1.2.3.4")

      # There are now 7 users - the five above, plus two extra "granters" for the
      # moderator_user and administrator_user
      assert_equal 7, User.count

      # Shouldn't work when not logged in
      get users_path
      assert_redirected_to login_path(:referer => users_path)

      session_for(user)

      # Shouldn't work when logged in as a normal user
      get users_path
      assert_redirected_to :controller => "/errors", :action => :forbidden

      session_for(moderator_user)

      # Shouldn't work when logged in as a moderator
      get users_path
      assert_redirected_to :controller => "/errors", :action => :forbidden

      session_for(administrator_user)

      # Note there is a header row, so all row counts are users + 1
      # Should work when logged in as an administrator
      get users_path
      assert_response :success
      assert_template :index
      assert_select "table#user_list tbody tr", :count => 7

      # Should be able to limit by status
      get users_path, :params => { :status => "suspended" }
      assert_response :success
      assert_template :index
      assert_select "table#user_list tbody tr", :count => 1

      # Should be able to limit by IP address
      get users_path, :params => { :ip => "1.2.3.4" }
      assert_response :success
      assert_template :index
      assert_select "table#user_list tbody tr", :count => 1
    end

    def test_index_get_paginated
      1.upto(100).each do |n|
        User.create(:display_name => "extra_#{n}",
                    :email => "extra#{n}@example.com",
                    :pass_crypt => "extraextra")
      end

      session_for(create(:administrator_user))

      # 100 examples, an administrator, and a granter for the admin.
      assert_equal 102, User.count
      next_path = users_path

      get next_path
      assert_response :success
      assert_template :index
      assert_select "table#user_list tbody tr", :count => 50
      check_no_page_link "Newer Users"
      next_path = check_page_link "Older Users"

      get next_path
      assert_response :success
      assert_template :index
      assert_select "table#user_list tbody tr", :count => 50
      check_page_link "Newer Users"
      next_path = check_page_link "Older Users"

      get next_path
      assert_response :success
      assert_template :index
      assert_select "table#user_list tbody tr", :count => 2
      check_page_link "Newer Users"
      check_no_page_link "Older Users"
    end

    def test_index_get_invalid_paginated
      session_for(create(:administrator_user))

      %w[-1 0 fred].each do |id|
        get users_path(:before => id)
        assert_redirected_to :controller => "/errors", :action => :bad_request

        get users_path(:after => id)
        assert_redirected_to :controller => "/errors", :action => :bad_request
      end
    end

    def test_index_post_confirm
      inactive_user = create(:user, :pending)
      suspended_user = create(:user, :suspended)

      # Shouldn't work when not logged in
      assert_no_difference "User.active.count" do
        post users_path, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
      end
      assert_response :forbidden

      assert_equal "pending", inactive_user.reload.status
      assert_equal "suspended", suspended_user.reload.status

      session_for(create(:user))

      # Shouldn't work when logged in as a normal user
      assert_no_difference "User.active.count" do
        post users_path, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
      end
      assert_redirected_to :controller => "/errors", :action => :forbidden
      assert_equal "pending", inactive_user.reload.status
      assert_equal "suspended", suspended_user.reload.status

      session_for(create(:moderator_user))

      # Shouldn't work when logged in as a moderator
      assert_no_difference "User.active.count" do
        post users_path, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
      end
      assert_redirected_to :controller => "/errors", :action => :forbidden
      assert_equal "pending", inactive_user.reload.status
      assert_equal "suspended", suspended_user.reload.status

      session_for(create(:administrator_user))

      # Should work when logged in as an administrator
      assert_difference "User.active.count", 2 do
        post users_path, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
      end
      assert_redirected_to :action => :index
      assert_equal "confirmed", inactive_user.reload.status
      assert_equal "confirmed", suspended_user.reload.status
    end

    def test_index_post_hide
      normal_user = create(:user)
      confirmed_user = create(:user, :confirmed)

      # Shouldn't work when not logged in
      assert_no_difference "User.active.count" do
        post users_path, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
      end
      assert_response :forbidden

      assert_equal "active", normal_user.reload.status
      assert_equal "confirmed", confirmed_user.reload.status

      session_for(create(:user))

      # Shouldn't work when logged in as a normal user
      assert_no_difference "User.active.count" do
        post users_path, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
      end
      assert_redirected_to :controller => "/errors", :action => :forbidden
      assert_equal "active", normal_user.reload.status
      assert_equal "confirmed", confirmed_user.reload.status

      session_for(create(:moderator_user))

      # Shouldn't work when logged in as a moderator
      assert_no_difference "User.active.count" do
        post users_path, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
      end
      assert_redirected_to :controller => "/errors", :action => :forbidden
      assert_equal "active", normal_user.reload.status
      assert_equal "confirmed", confirmed_user.reload.status

      session_for(create(:administrator_user))

      # Should work when logged in as an administrator
      assert_difference "User.active.count", -2 do
        post users_path, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
      end
      assert_redirected_to :action => :index
      assert_equal "deleted", normal_user.reload.status
      assert_equal "deleted", confirmed_user.reload.status
    end

    private

    def check_no_page_link(name)
      assert_select "a.page-link", { :text => /#{Regexp.quote(name)}/, :count => 0 }, "unexpected #{name} page link"
    end

    def check_page_link(name)
      assert_select "a.page-link", { :text => /#{Regexp.quote(name)}/ }, "missing #{name} page link" do |buttons|
        return buttons.first.attributes["href"].value
      end
    end
  end
end
