require "test_helper"
require_relative "users/details_test_helper"

module Api
  class UsersControllerTest < ActionDispatch::IntegrationTest
    include Users::DetailsTestHelper

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/user/1", :method => :get },
        { :controller => "api/users", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/user/1.json", :method => :get },
        { :controller => "api/users", :action => "show", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/users", :method => :get },
        { :controller => "api/users", :action => "index" }
      )
      assert_routing(
        { :path => "/api/0.6/users.json", :method => :get },
        { :controller => "api/users", :action => "index", :format => "json" }
      )
    end

    def test_show
      user = create(:user,
                    :description => "test",
                    :terms_agreed => Date.yesterday,
                    :home_lat => 12.1, :home_lon => 23.4,
                    :languages => ["en"])

      # check that a visible user is returned properly
      get api_user_path(:id => user.id)
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, false, false)

      # check that a suspended user is not returned
      get api_user_path(:id => create(:user, :suspended).id)
      assert_response :gone

      # check that a deleted user is not returned
      get api_user_path(:id => create(:user, :deleted).id)
      assert_response :gone

      # check that a non-existent user is not returned
      get api_user_path(:id => 0)
      assert_response :not_found

      # check that a visible user is returned properly in json
      get api_user_path(:id => user.id, :format => "json")
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, false, false)
    end

    def test_show_oauth2
      user = create(:user,
                    :home_lat => 12.1, :home_lon => 23.4,
                    :languages => ["en"])
      good_auth = bearer_authorization_header(user, :scopes => %w[read_prefs])
      bad_auth = bearer_authorization_header(user, :scopes => %w[])
      other_user = create(:user,
                          :home_lat => 12.1, :home_lon => 23.4,
                          :languages => ["en"])

      # check that we can fetch our own details as XML with read_prefs
      get api_user_path(:id => user.id), :headers => good_auth
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, true, false)

      # check that we can fetch a different user's details as XML with read_prefs
      get api_user_path(:id => other_user.id), :headers => good_auth
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(other_user, false, false)

      # check that we can fetch our own details as XML without read_prefs
      get api_user_path(:id => user.id), :headers => bad_auth
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, false, false)

      # check that we can fetch our own details as JSON with read_prefs
      get api_user_path(:id => user.id, :format => "json"), :headers => good_auth
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, true, false)

      # check that we can fetch a different user's details as JSON with read_prefs
      get api_user_path(:id => other_user.id, :format => "json"), :headers => good_auth
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, other_user, false, false)

      # check that we can fetch our own details as JSON without read_prefs
      get api_user_path(:id => user.id, :format => "json"), :headers => bad_auth
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, false, false)
    end

    def test_index
      user1 = create(:user, :description => "test1", :terms_agreed => Date.yesterday)
      user2 = create(:user, :description => "test2", :terms_agreed => Date.yesterday)
      user3 = create(:user, :description => "test3", :terms_agreed => Date.yesterday)

      get api_users_path, :params => { :users => user1.id }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 1 do
        check_xml_details(user1, false, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      get api_users_path, :params => { :users => user2.id }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 1 do
        assert_select "user[id='#{user1.id}']", :count => 0
        check_xml_details(user2, false, false)
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}" }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 2 do
        check_xml_details(user1, false, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        check_xml_details(user3, false, false)
      end

      get api_users_path, :params => { :users => user1.id, :format => "json" }
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["users"].count
      check_json_details(js["users"][0], user1, false, false)

      get api_users_path, :params => { :users => user2.id, :format => "json" }
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["users"].count
      check_json_details(js["users"][0], user2, false, false)

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}", :format => "json" }
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["users"].count
      check_json_details(js["users"][0], user1, false, false)
      check_json_details(js["users"][1], user3, false, false)

      get api_users_path, :params => { :users => create(:user, :suspended).id }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 0

      get api_users_path, :params => { :users => create(:user, :deleted).id }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 0

      get api_users_path, :params => { :users => 0 }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 0
    end

    def test_index_oauth2
      user1 = create(:user, :description => "test1", :terms_agreed => Date.yesterday)
      user2 = create(:user, :description => "test2", :terms_agreed => Date.yesterday)
      user3 = create(:user, :description => "test3", :terms_agreed => Date.yesterday)
      good_auth = bearer_authorization_header(user1, :scopes => %w[read_prefs])
      bad_auth = bearer_authorization_header(user1, :scopes => %w[])

      get api_users_path, :params => { :users => user1.id }, :headers => good_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 1 do
        check_xml_details(user1, true, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      get api_users_path, :params => { :users => user2.id }, :headers => good_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 1 do
        assert_select "user[id='#{user1.id}']", :count => 0
        check_xml_details(user2, false, false)
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}" }, :headers => good_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 2 do
        check_xml_details(user1, true, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        check_xml_details(user3, false, false)
      end

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}" }, :headers => bad_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 2 do
        check_xml_details(user1, false, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        check_xml_details(user3, false, false)
      end

      get api_users_path, :params => { :users => user1.id, :format => "json" }, :headers => good_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["users"].count
      check_json_details(js["users"][0], user1, true, false)

      get api_users_path, :params => { :users => user2.id, :format => "json" }, :headers => good_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["users"].count
      check_json_details(js["users"][0], user2, false, false)

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}", :format => "json" }, :headers => good_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["users"].count
      check_json_details(js["users"][0], user1, true, false)
      check_json_details(js["users"][1], user3, false, false)

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}", :format => "json" }, :headers => bad_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["users"].count
      check_json_details(js["users"][0], user1, false, false)
      check_json_details(js["users"][1], user3, false, false)

      get api_users_path, :params => { :users => create(:user, :suspended).id }, :headers => good_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 0

      get api_users_path, :params => { :users => create(:user, :deleted).id }, :headers => good_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 0

      get api_users_path, :params => { :users => 0 }, :headers => good_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 0
    end
  end
end
