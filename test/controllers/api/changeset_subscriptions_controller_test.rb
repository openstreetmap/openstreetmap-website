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

    def test_create_by_unauthorized
      changeset = create(:changeset, :closed)

      assert_no_difference "ChangesetSubscription.count" do
        assert_no_difference "changeset.subscribers.count" do
          post api_changeset_subscription_path(changeset)

          assert_response :unauthorized
        end
      end
    end

    def test_create_on_missing_changeset
      user = create(:user)
      auth_header = bearer_authorization_header user

      assert_no_difference "ChangesetSubscription.count" do
        post api_changeset_subscription_path(999111), :headers => auth_header

        assert_response :not_found
      end
    end

    def test_create_when_subscribed
      user = create(:user)
      auth_header = bearer_authorization_header user
      changeset = create(:changeset, :closed)
      changeset.subscribers << user

      assert_no_difference "ChangesetSubscription.count" do
        assert_no_difference "changeset.subscribers.count" do
          post api_changeset_subscription_path(changeset), :headers => auth_header

          assert_response :conflict
        end
      end
    end

    def test_create_on_open_changeset
      user = create(:user)
      auth_header = bearer_authorization_header user
      changeset = create(:changeset)

      assert_difference "ChangesetSubscription.count", 1 do
        assert_difference "changeset.subscribers.count", 1 do
          post api_changeset_subscription_path(changeset), :headers => auth_header

          assert_response :success
        end
      end
    end

    def test_create_on_closed_changeset
      user = create(:user)
      auth_header = bearer_authorization_header user
      changeset = create(:changeset, :closed)

      assert_difference "ChangesetSubscription.count", 1 do
        assert_difference "changeset.subscribers.count", 1 do
          post api_changeset_subscription_path(changeset), :headers => auth_header

          assert_response :success
        end
      end
    end

    def test_destroy_by_unauthorized
      changeset = create(:changeset, :closed)

      assert_no_difference "ChangesetSubscription.count" do
        assert_no_difference "changeset.subscribers.count" do
          delete api_changeset_subscription_path(changeset)

          assert_response :unauthorized
        end
      end
    end

    def test_destroy_on_missing_changeset
      user = create(:user)
      auth_header = bearer_authorization_header user

      assert_no_difference "ChangesetSubscription.count" do
        delete api_changeset_subscription_path(999111), :headers => auth_header

        assert_response :not_found
      end
    end

    def test_destroy_when_not_subscribed
      user = create(:user)
      auth_header = bearer_authorization_header user
      changeset = create(:changeset, :closed)

      assert_no_difference "ChangesetSubscription.count" do
        assert_no_difference "changeset.subscribers.count" do
          delete api_changeset_subscription_path(changeset), :headers => auth_header

          assert_response :not_found
        end
      end
    end

    def test_destroy_on_open_changeset
      user = create(:user)
      auth_header = bearer_authorization_header user
      changeset = create(:changeset)
      changeset.subscribers.push(user)

      assert_difference "ChangesetSubscription.count", -1 do
        assert_difference "changeset.subscribers.count", -1 do
          delete api_changeset_subscription_path(changeset), :headers => auth_header

          assert_response :success
        end
      end
    end

    def test_destroy_on_closed_changeset
      user = create(:user)
      auth_header = bearer_authorization_header user
      changeset = create(:changeset, :closed)
      changeset.subscribers.push(user)

      assert_difference "ChangesetSubscription.count", -1 do
        assert_difference "changeset.subscribers.count", -1 do
          delete api_changeset_subscription_path(changeset), :headers => auth_header

          assert_response :success
        end
      end
    end
  end
end
