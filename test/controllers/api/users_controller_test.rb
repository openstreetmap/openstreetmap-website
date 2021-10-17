require "test_helper"

module Api
  class UsersControllerTest < ActionDispatch::IntegrationTest
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
        { :path => "/api/0.6/user/details", :method => :get },
        { :controller => "api/users", :action => "details" }
      )
      assert_routing(
        { :path => "/api/0.6/user/details.json", :method => :get },
        { :controller => "api/users", :action => "details", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/user/gpx_files", :method => :get },
        { :controller => "api/users", :action => "gpx_files" }
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

    def test_show_oauth1
      user = create(:user,
                    :home_lat => 12.1, :home_lon => 23.4,
                    :languages => ["en"])
      good_token = create(:access_token,
                          :user => user,
                          :allow_read_prefs => true)
      bad_token = create(:access_token,
                         :user => user)
      other_user = create(:user,
                          :home_lat => 12.1, :home_lon => 23.4,
                          :languages => ["en"])

      # check that we can fetch our own details as XML with read_prefs
      signed_get api_user_path(:id => user.id), :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, true, false)

      # check that we can fetch a different user's details as XML with read_prefs
      signed_get api_user_path(:id => other_user.id), :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(other_user, false, false)

      # check that we can fetch our own details as XML without read_prefs
      signed_get api_user_path(:id => user.id), :oauth => { :token => bad_token }
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, false, false)

      # check that we can fetch our own details as JSON with read_prefs
      signed_get api_user_path(:id => user.id, :format => "json"), :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, true, false)

      # check that we can fetch a different user's details as JSON with read_prefs
      signed_get api_user_path(:id => other_user.id, :format => "json"), :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, other_user, false, false)

      # check that we can fetch our own details as JSON without read_prefs
      signed_get api_user_path(:id => other_user.id, :format => "json"), :oauth => { :token => bad_token }
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, other_user, false, false)
    end

    def test_show_oauth2
      user = create(:user,
                    :home_lat => 12.1, :home_lon => 23.4,
                    :languages => ["en"])
      good_token = create(:oauth_access_token,
                          :resource_owner_id => user.id,
                          :scopes => %w[read_prefs])
      bad_token = create(:oauth_access_token,
                         :resource_owner_id => user.id,
                         :scopes => %w[])
      other_user = create(:user,
                          :home_lat => 12.1, :home_lon => 23.4,
                          :languages => ["en"])

      # check that we can fetch our own details as XML with read_prefs
      get api_user_path(:id => user.id), :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, true, false)

      # check that we can fetch a different user's details as XML with read_prefs
      get api_user_path(:id => other_user.id), :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(other_user, false, false)

      # check that we can fetch our own details as XML without read_prefs
      get api_user_path(:id => user.id), :headers => bearer_authorization_header(bad_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, false, false)

      # check that we can fetch our own details as JSON with read_prefs
      get api_user_path(:id => user.id, :format => "json"), :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, true, false)

      # check that we can fetch a different user's details as JSON with read_prefs
      get api_user_path(:id => other_user.id, :format => "json"), :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, other_user, false, false)

      # check that we can fetch our own details as JSON without read_prefs
      get api_user_path(:id => user.id, :format => "json"), :headers => bearer_authorization_header(bad_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, false, false)
    end

    def test_details
      user = create(:user,
                    :description => "test",
                    :terms_agreed => Date.yesterday,
                    :home_lat => 12.1, :home_lon => 23.4,
                    :languages => ["en"])
      create(:message, :read, :recipient => user)
      create(:message, :sender => user)

      # check that nothing is returned when not logged in
      get user_details_path
      assert_response :unauthorized

      # check that we get a response when logged in
      auth_header = basic_authorization_header user.email, "test"
      get user_details_path, :headers => auth_header
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, true, false)

      # check that data is returned properly in json
      auth_header = basic_authorization_header user.email, "test"
      get user_details_path(:format => "json"), :headers => auth_header
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, true, false)
    end

    def test_details_oauth1
      user = create(:user,
                    :home_lat => 12.1, :home_lon => 23.4,
                    :languages => ["en"])
      good_token = create(:access_token,
                          :user => user,
                          :allow_read_prefs => true)
      bad_token = create(:access_token,
                         :user => user)

      # check that we can't fetch details as XML without read_prefs
      signed_get user_details_path, :oauth => { :token => bad_token }
      assert_response :forbidden

      # check that we can fetch details as XML
      signed_get user_details_path, :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, true, false)

      # check that we can't fetch details as JSON without read_prefs
      signed_get user_details_path(:format => "json"), :oauth => { :token => bad_token }
      assert_response :forbidden

      # check that we can fetch details as JSON
      signed_get user_details_path(:format => "json"), :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, true, false)
    end

    def test_details_oauth2
      user = create(:user,
                    :home_lat => 12.1, :home_lon => 23.4,
                    :languages => ["en"])
      good_token = create(:oauth_access_token,
                          :resource_owner_id => user.id,
                          :scopes => %w[read_prefs])
      bad_token = create(:oauth_access_token,
                         :resource_owner_id => user.id)
      email_token = create(:oauth_access_token,
                           :resource_owner_id => user.id,
                           :scopes => %w[read_prefs read_email])

      # check that we can't fetch details as XML without read_prefs
      get user_details_path, :headers => bearer_authorization_header(bad_token.token)
      assert_response :forbidden

      # check that we can fetch details as XML without read_email
      get user_details_path, :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, true, false)

      # check that we can fetch details as XML with read_email
      get user_details_path, :headers => bearer_authorization_header(email_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      check_xml_details(user, true, true)

      # check that we can't fetch details as JSON without read_prefs
      get user_details_path(:format => "json"), :headers => bearer_authorization_header(bad_token.token)
      assert_response :forbidden

      # check that we can fetch details as JSON without read_email
      get user_details_path(:format => "json"), :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, true, false)

      # check that we can fetch details as JSON with read_email
      get user_details_path(:format => "json"), :headers => bearer_authorization_header(email_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type

      # parse the response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      # check the data that is returned
      check_json_details(js, user, true, true)
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
      assert_response :not_found

      get api_users_path, :params => { :users => create(:user, :deleted).id }
      assert_response :not_found

      get api_users_path, :params => { :users => 0 }
      assert_response :not_found
    end

    def test_index_oauth1
      user1 = create(:user, :description => "test1", :terms_agreed => Date.yesterday)
      user2 = create(:user, :description => "test2", :terms_agreed => Date.yesterday)
      user3 = create(:user, :description => "test3", :terms_agreed => Date.yesterday)
      good_token = create(:access_token, :user => user1, :allow_read_prefs => true)
      bad_token = create(:access_token, :user => user1)

      signed_get api_users_path, :params => { :users => user1.id }, :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 1 do
        check_xml_details(user1, true, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      signed_get api_users_path, :params => { :users => user2.id }, :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 1 do
        assert_select "user[id='#{user1.id}']", :count => 0
        check_xml_details(user2, false, false)
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      signed_get api_users_path, :params => { :users => "#{user1.id},#{user3.id}" }, :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 2 do
        check_xml_details(user1, true, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        check_xml_details(user3, false, false)
      end

      signed_get api_users_path, :params => { :users => "#{user1.id},#{user3.id}" }, :oauth => { :token => bad_token }
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 2 do
        check_xml_details(user1, false, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        check_xml_details(user3, false, false)
      end

      signed_get api_users_path, :params => { :users => user1.id, :format => "json" }, :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["users"].count
      check_json_details(js["users"][0], user1, true, false)

      signed_get api_users_path, :params => { :users => user2.id, :format => "json" }, :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["users"].count
      check_json_details(js["users"][0], user2, false, false)

      signed_get api_users_path, :params => { :users => "#{user1.id},#{user3.id}", :format => "json" }, :oauth => { :token => good_token }
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["users"].count
      check_json_details(js["users"][0], user1, true, false)
      check_json_details(js["users"][1], user3, false, false)

      signed_get api_users_path, :params => { :users => "#{user1.id},#{user3.id}", :format => "json" }, :oauth => { :token => bad_token }
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["users"].count
      check_json_details(js["users"][0], user1, false, false)
      check_json_details(js["users"][1], user3, false, false)

      signed_get api_users_path, :params => { :users => create(:user, :suspended).id }, :oauth => { :token => good_token }
      assert_response :not_found

      signed_get api_users_path, :params => { :users => create(:user, :deleted).id }, :oauth => { :token => good_token }
      assert_response :not_found

      signed_get api_users_path, :params => { :users => 0 }, :oauth => { :token => good_token }
      assert_response :not_found
    end

    def test_index_oauth2
      user1 = create(:user, :description => "test1", :terms_agreed => Date.yesterday)
      user2 = create(:user, :description => "test2", :terms_agreed => Date.yesterday)
      user3 = create(:user, :description => "test3", :terms_agreed => Date.yesterday)
      good_token = create(:oauth_access_token, :resource_owner_id => user1.id, :scopes => %w[read_prefs])
      bad_token = create(:oauth_access_token, :resource_owner_id => user1.id, :scopes => %w[])

      get api_users_path, :params => { :users => user1.id }, :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 1 do
        check_xml_details(user1, true, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      get api_users_path, :params => { :users => user2.id }, :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 1 do
        assert_select "user[id='#{user1.id}']", :count => 0
        check_xml_details(user2, false, false)
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}" }, :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 2 do
        check_xml_details(user1, true, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        check_xml_details(user3, false, false)
      end

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}" }, :headers => bearer_authorization_header(bad_token.token)
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "user", :count => 2 do
        check_xml_details(user1, false, false)
        assert_select "user[id='#{user2.id}']", :count => 0
        check_xml_details(user3, false, false)
      end

      get api_users_path, :params => { :users => user1.id, :format => "json" }, :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["users"].count
      check_json_details(js["users"][0], user1, true, false)

      get api_users_path, :params => { :users => user2.id, :format => "json" }, :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["users"].count
      check_json_details(js["users"][0], user2, false, false)

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}", :format => "json" }, :headers => bearer_authorization_header(good_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["users"].count
      check_json_details(js["users"][0], user1, true, false)
      check_json_details(js["users"][1], user3, false, false)

      get api_users_path, :params => { :users => "#{user1.id},#{user3.id}", :format => "json" }, :headers => bearer_authorization_header(bad_token.token)
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["users"].count
      check_json_details(js["users"][0], user1, false, false)
      check_json_details(js["users"][1], user3, false, false)

      get api_users_path, :params => { :users => create(:user, :suspended).id }, :headers => bearer_authorization_header(good_token.token)
      assert_response :not_found

      get api_users_path, :params => { :users => create(:user, :deleted).id }, :headers => bearer_authorization_header(good_token.token)
      assert_response :not_found

      get api_users_path, :params => { :users => 0 }, :headers => bearer_authorization_header(good_token.token)
      assert_response :not_found
    end

    def test_gpx_files
      user = create(:user)
      trace1 = create(:trace, :user => user) do |trace|
        create(:tracetag, :trace => trace, :tag => "London")
      end
      trace2 = create(:trace, :user => user) do |trace|
        create(:tracetag, :trace => trace, :tag => "Birmingham")
      end
      # check that nothing is returned when not logged in
      get user_gpx_files_path
      assert_response :unauthorized

      # check that we get a response when logged in
      auth_header = basic_authorization_header user.email, "test"
      get user_gpx_files_path, :headers => auth_header
      assert_response :success
      assert_equal "application/xml", response.media_type

      # check the data that is returned
      assert_select "gpx_file[id='#{trace1.id}']", 1 do
        assert_select "tag", "London"
      end
      assert_select "gpx_file[id='#{trace2.id}']", 1 do
        assert_select "tag", "Birmingham"
      end
    end

    private

    def check_xml_details(user, include_private, include_email)
      assert_select "user[id='#{user.id}']", :count => 1 do
        assert_select "description", :count => 1, :text => user.description

        assert_select "contributor-terms", :count => 1 do
          if user.terms_agreed.present?
            assert_select "[agreed='true']", :count => 1
          else
            assert_select "[agreed='false']", :count => 1
          end

          if include_private
            assert_select "[pd='false']", :count => 1
          else
            assert_select "[pd]", :count => 0
          end
        end

        assert_select "img", :count => 0

        assert_select "roles", :count => 1 do
          assert_select "role", :count => 0
        end

        assert_select "changesets", :count => 1 do
          assert_select "[count='0']", :count => 1
        end

        assert_select "traces", :count => 1 do
          assert_select "[count='0']", :count => 1
        end

        assert_select "blocks", :count => 1 do
          assert_select "received", :count => 1 do
            assert_select "[count='0'][active='0']", :count => 1
          end

          assert_select "issued", :count => 0
        end

        if include_private && user.home_lat.present? && user.home_lon.present?
          assert_select "home", :count => 1 do
            assert_select "[lat='12.1'][lon='23.4'][zoom='3']", :count => 1
          end
        else
          assert_select "home", :count => 0
        end

        if include_private
          assert_select "languages", :count => 1 do
            assert_select "lang", :count => user.languages.count

            user.languages.each do |language|
              assert_select "lang", :count => 1, :text => language
            end
          end

          assert_select "messages", :count => 1 do
            assert_select "received", :count => 1 do
              assert_select "[count='#{user.messages.count}'][unread='0']", :count => 1
            end

            assert_select "sent", :count => 1 do
              assert_select "[count='#{user.sent_messages.count}']", :count => 1
            end
          end
        else
          assert_select "languages", :count => 0
          assert_select "messages", :count => 0
        end

        if include_email
          assert_select "email", :count => 1, :text => user.email
        else
          assert_select "email", :count => 0
        end
      end
    end

    def check_json_details(js, user, include_private, include_email)
      assert_equal user.id, js["user"]["id"]
      assert_equal user.description, js["user"]["description"]
      assert js["user"]["contributor_terms"]["agreed"]

      if include_private
        assert_not js["user"]["contributor_terms"]["pd"]
      else
        assert_nil js["user"]["contributor_terms"]["pd"]
      end

      assert_nil js["user"]["img"]
      assert_empty js["user"]["roles"]
      assert_equal 0, js["user"]["changesets"]["count"]
      assert_equal 0, js["user"]["traces"]["count"]
      assert_equal 0, js["user"]["blocks"]["received"]["count"]
      assert_equal 0, js["user"]["blocks"]["received"]["active"]
      assert_nil js["user"]["blocks"]["issued"]

      if include_private && user.home_lat.present? && user.home_lon.present?
        assert_in_delta 12.1, js["user"]["home"]["lat"]
        assert_in_delta 23.4, js["user"]["home"]["lon"]
        assert_equal 3, js["user"]["home"]["zoom"]
      else
        assert_nil js["user"]["home"]
      end

      if include_private && user.languages.present?
        assert_equal user.languages, js["user"]["languages"]
      else
        assert_nil js["user"]["languages"]
      end

      if include_private
        assert_equal user.messages.count, js["user"]["messages"]["received"]["count"]
        assert_equal 0, js["user"]["messages"]["received"]["unread"]
        assert_equal user.sent_messages.count, js["user"]["messages"]["sent"]["count"]
      else
        assert_nil js["user"]["messages"]
      end

      if include_email
        assert_equal user.email, js["user"]["email"]
      else
        assert_nil js["user"]["email"]
      end
    end
  end
end
