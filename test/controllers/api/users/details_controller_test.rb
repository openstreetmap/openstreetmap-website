require "test_helper"
require_relative "details_test_helper"

module Api
  module Users
    class DetailsControllerTest < ActionDispatch::IntegrationTest
      include Users::DetailsTestHelper

      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/user/details", :method => :get },
          { :controller => "api/users/details", :action => "show" }
        )
        assert_routing(
          { :path => "/api/0.6/user/details.json", :method => :get },
          { :controller => "api/users/details", :action => "show", :format => "json" }
        )
      end

      def test_show
        user = create(:user,
                      :description => "test",
                      :terms_agreed => Date.yesterday,
                      :home_lat => 12.1, :home_lon => 23.4,
                      :languages => ["en"])
        create(:message, :read, :recipient => user)
        create(:message, :sender => user)

        # check that nothing is returned when not logged in
        get api_user_details_path
        assert_response :unauthorized

        # check that we get a response when logged in
        auth_header = bearer_authorization_header user
        get api_user_details_path, :headers => auth_header
        assert_response :success
        assert_equal "application/xml", response.media_type

        # check the data that is returned
        check_xml_details(user, true, false)

        # check that data is returned properly in json
        auth_header = bearer_authorization_header user
        get api_user_details_path(:format => "json"), :headers => auth_header
        assert_response :success
        assert_equal "application/json", response.media_type

        # parse the response
        js = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil js

        # check the data that is returned
        check_json_details(js, user, true, false)
      end

      def test_show_oauth2
        user = create(:user,
                      :home_lat => 12.1, :home_lon => 23.4,
                      :languages => ["en"])
        good_auth = bearer_authorization_header(user, :scopes => %w[read_prefs])
        bad_auth = bearer_authorization_header(user, :scopes => %w[])
        email_auth = bearer_authorization_header(user, :scopes => %w[read_prefs read_email])

        # check that we can't fetch details as XML without read_prefs
        get api_user_details_path, :headers => bad_auth
        assert_response :forbidden

        # check that we can fetch details as XML without read_email
        get api_user_details_path, :headers => good_auth
        assert_response :success
        assert_equal "application/xml", response.media_type

        # check the data that is returned
        check_xml_details(user, true, false)

        # check that we can fetch details as XML with read_email
        get api_user_details_path, :headers => email_auth
        assert_response :success
        assert_equal "application/xml", response.media_type

        # check the data that is returned
        check_xml_details(user, true, true)

        # check that we can't fetch details as JSON without read_prefs
        get api_user_details_path(:format => "json"), :headers => bad_auth
        assert_response :forbidden

        # check that we can fetch details as JSON without read_email
        get api_user_details_path(:format => "json"), :headers => good_auth
        assert_response :success
        assert_equal "application/json", response.media_type

        # parse the response
        js = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil js

        # check the data that is returned
        check_json_details(js, user, true, false)

        # check that we can fetch details as JSON with read_email
        get api_user_details_path(:format => "json"), :headers => email_auth
        assert_response :success
        assert_equal "application/json", response.media_type

        # parse the response
        js = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil js

        # check the data that is returned
        check_json_details(js, user, true, true)
      end
    end
  end
end
