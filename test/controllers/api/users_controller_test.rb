require "test_helper"

module Api
  class UsersControllerTest < ActionController::TestCase
    def setup
      super

      stub_hostip_requests
    end

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/user/1", :method => :get },
        { :controller => "api/users", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/user/details", :method => :get },
        { :controller => "api/users", :action => "details" }
      )
      assert_routing(
        { :path => "/api/0.6/user/gpx_files", :method => :get },
        { :controller => "api/users", :action => "gpx_files" }
      )
      assert_routing(
        { :path => "/api/0.6/users", :method => :get },
        { :controller => "api/users", :action => "index" }
      )
    end

    def test_show
      user = create(:user, :description => "test", :terms_agreed => Date.yesterday)
      # check that a visible user is returned properly
      get :show, :params => { :id => user.id }
      assert_response :success
      assert_equal "text/xml", response.content_type

      # check the data that is returned
      assert_select "description", :count => 1, :text => "test"
      assert_select "contributor-terms", :count => 1 do
        assert_select "[agreed='true']"
      end
      assert_select "img", :count => 0
      assert_select "roles", :count => 1 do
        assert_select "role", :count => 0
      end
      assert_select "changesets", :count => 1 do
        assert_select "[count='0']"
      end
      assert_select "traces", :count => 1 do
        assert_select "[count='0']"
      end
      assert_select "blocks", :count => 1 do
        assert_select "received", :count => 1 do
          assert_select "[count='0'][active='0']"
        end
        assert_select "issued", :count => 0
      end

      # check that we aren't revealing private information
      assert_select "contributor-terms[pd]", false
      assert_select "home", false
      assert_select "languages", false
      assert_select "messages", false

      # check that a suspended user is not returned
      get :show, :params => { :id => create(:user, :suspended).id }
      assert_response :gone

      # check that a deleted user is not returned
      get :show, :params => { :id => create(:user, :deleted).id }
      assert_response :gone

      # check that a non-existent user is not returned
      get :show, :params => { :id => 0 }
      assert_response :not_found
    end

    def test_details
      user = create(:user, :description => "test", :terms_agreed => Date.yesterday, :home_lat => 12.1, :home_lon => 12.1, :languages => ["en"])
      create(:message, :read, :recipient => user)
      create(:message, :sender => user)

      # check that nothing is returned when not logged in
      get :details
      assert_response :unauthorized

      # check that we get a response when logged in
      basic_authorization user.email, "test"
      get :details
      assert_response :success
      assert_equal "text/xml", response.content_type

      # check the data that is returned
      assert_select "description", :count => 1, :text => "test"
      assert_select "contributor-terms", :count => 1 do
        assert_select "[agreed='true'][pd='false']"
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
          assert_select "[count='0'][active='0']"
        end
        assert_select "issued", :count => 0
      end
      assert_select "home", :count => 1 do
        assert_select "[lat='12.1'][lon='12.1'][zoom='3']"
      end
      assert_select "languages", :count => 1 do
        assert_select "lang", :count => 1, :text => "en"
      end
      assert_select "messages", :count => 1 do
        assert_select "received", :count => 1 do
          assert_select "[count='1'][unread='0']"
        end
        assert_select "sent", :count => 1 do
          assert_select "[count='1']"
        end
      end
    end

    def test_index
      user1 = create(:user, :description => "test1", :terms_agreed => Date.yesterday)
      user2 = create(:user, :description => "test2", :terms_agreed => Date.yesterday)
      user3 = create(:user, :description => "test3", :terms_agreed => Date.yesterday)

      get :index, :params => { :users => user1.id }
      assert_response :success
      assert_equal "text/xml", response.content_type
      assert_select "user", :count => 1 do
        assert_select "user[id='#{user1.id}']", :count => 1
        assert_select "user[id='#{user2.id}']", :count => 0
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      get :index, :params => { :users => user2.id }
      assert_response :success
      assert_equal "text/xml", response.content_type
      assert_select "user", :count => 1 do
        assert_select "user[id='#{user1.id}']", :count => 0
        assert_select "user[id='#{user2.id}']", :count => 1
        assert_select "user[id='#{user3.id}']", :count => 0
      end

      get :index, :params => { :users => "#{user1.id},#{user3.id}" }
      assert_response :success
      assert_equal "text/xml", response.content_type
      assert_select "user", :count => 2 do
        assert_select "user[id='#{user1.id}']", :count => 1
        assert_select "user[id='#{user2.id}']", :count => 0
        assert_select "user[id='#{user3.id}']", :count => 1
      end

      get :index, :params => { :users => create(:user, :suspended).id }
      assert_response :not_found

      get :index, :params => { :users => create(:user, :deleted).id }
      assert_response :not_found

      get :index, :params => { :users => 0 }
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
      get :gpx_files
      assert_response :unauthorized

      # check that we get a response when logged in
      basic_authorization user.email, "test"
      get :gpx_files
      assert_response :success
      assert_equal "application/xml", response.content_type

      # check the data that is returned
      assert_select "gpx_file[id='#{trace1.id}']", 1 do
        assert_select "tag", "London"
      end
      assert_select "gpx_file[id='#{trace2.id}']", 1 do
        assert_select "tag", "Birmingham"
      end
    end
  end
end
