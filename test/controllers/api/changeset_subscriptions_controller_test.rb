require "test_helper"

module Api
  class ChangesetsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/changeset/1/subscription", :method => :post },
        { :controller => "api/changeset_subscriptions", :action => "create", :changeset_id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/subscription.json", :method => :post },
        { :controller => "api/changeset_subscriptions", :action => "create", :changeset_id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/subscription", :method => :delete },
        { :controller => "api/changeset_subscriptions", :action => "destroy", :changeset_id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/subscription.json", :method => :delete },
        { :controller => "api/changeset_subscriptions", :action => "destroy", :changeset_id => "1", :format => "json" }
      )
    end

    def test_create_success
      auth_header = bearer_authorization_header
      changeset = create(:changeset, :closed)

      assert_difference "changeset.subscribers.count", 1 do
        post api_changeset_subscription_path(changeset), :headers => auth_header
      end
      assert_response :success

      # not closed changeset
      changeset = create(:changeset)
      assert_difference "changeset.subscribers.count", 1 do
        post api_changeset_subscription_path(changeset), :headers => auth_header
      end
      assert_response :success
    end

    def test_create_fail
      user = create(:user)

      # unauthorized
      changeset = create(:changeset, :closed)
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_subscription_path(changeset)
      end
      assert_response :unauthorized

      auth_header = bearer_authorization_header user

      # bad changeset id
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_subscription_path(999111), :headers => auth_header
      end
      assert_response :not_found

      # trying to subscribe when already subscribed
      changeset = create(:changeset, :closed)
      changeset.subscribers.push(user)
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_subscription_path(changeset), :headers => auth_header
      end
      assert_response :conflict
    end

    def test_destroy_success
      user = create(:user)
      auth_header = bearer_authorization_header user
      changeset = create(:changeset, :closed)
      changeset.subscribers.push(user)

      assert_difference "changeset.subscribers.count", -1 do
        delete api_changeset_subscription_path(changeset), :headers => auth_header
      end
      assert_response :success

      # not closed changeset
      changeset = create(:changeset)
      changeset.subscribers.push(user)

      assert_difference "changeset.subscribers.count", -1 do
        delete api_changeset_subscription_path(changeset), :headers => auth_header
      end
      assert_response :success
    end

    def test_destroy_fail
      # unauthorized
      changeset = create(:changeset, :closed)
      assert_no_difference "changeset.subscribers.count" do
        delete api_changeset_subscription_path(changeset)
      end
      assert_response :unauthorized

      auth_header = bearer_authorization_header

      # bad changeset id
      assert_no_difference "changeset.subscribers.count" do
        delete api_changeset_subscription_path(999111), :headers => auth_header
      end
      assert_response :not_found

      # trying to unsubscribe when not subscribed
      changeset = create(:changeset, :closed)
      assert_no_difference "changeset.subscribers.count" do
        delete api_changeset_subscription_path(changeset), :headers => auth_header
      end
      assert_response :not_found
    end
  end
end
