require "test_helper"

module Api
  class NoteSubscriptionsControllerTest < ActionDispatch::IntegrationTest
    def test_routes
      assert_routing(
        { :path => "/api/0.6/notes/1/subscription", :method => :post },
        { :controller => "api/note_subscriptions", :action => "create", :note_id => "1" }
      )
    end

    def test_create
      user = create(:user)
      auth_header = bearer_authorization_header user
      note = create(:note_with_comments)
      assert_empty note.subscribers

      assert_difference "NoteSubscription.count", 1 do
        assert_difference "note.subscribers.count", 1 do
          post api_note_subscription_path(note), :headers => auth_header
          assert_response :success
        end
      end
      assert_equal user, note.subscribers.last
    end

    def test_create_fail_anonymous
      note = create(:note_with_comments)

      assert_no_difference "NoteSubscription.count" do
        assert_no_difference "note.subscribers.count" do
          post api_note_subscription_path(note)
          assert_response :unauthorized
        end
      end
    end

    def test_create_fail_no_scope
      user = create(:user)
      auth_header = bearer_authorization_header user, :scopes => %w[read_prefs]
      note = create(:note_with_comments)

      assert_no_difference "NoteSubscription.count" do
        assert_no_difference "note.subscribers.count" do
          post api_note_subscription_path(note), :headers => auth_header
          assert_response :forbidden
        end
      end
    end

    def test_create_fail_note_not_found
      user = create(:user)
      auth_header = bearer_authorization_header user

      assert_no_difference "NoteSubscription.count" do
        post api_note_subscription_path(999111), :headers => auth_header
        assert_response :not_found
      end
      assert_match "not found", @response.body
    end

    def test_create_fail_already_subscribed
      user = create(:user)
      auth_header = bearer_authorization_header user
      note = create(:note_with_comments)
      create(:note_subscription, :user => user, :note => note)

      assert_no_difference "NoteSubscription.count" do
        assert_no_difference "note.subscribers.count" do
          post api_note_subscription_path(note), :headers => auth_header
          assert_response :conflict
        end
      end
      assert_match "already subscribed", @response.body
    end
  end
end
