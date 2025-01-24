require "test_helper"

class ChangesetSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/changeset/1/subscription", :method => :get },
      { :controller => "changeset_subscriptions", :action => "show", :changeset_id => "1" }
    )
    assert_routing(
      { :path => "/changeset/1/subscription", :method => :post },
      { :controller => "changeset_subscriptions", :action => "create", :changeset_id => "1" }
    )
    assert_routing(
      { :path => "/changeset/1/subscription", :method => :delete },
      { :controller => "changeset_subscriptions", :action => "destroy", :changeset_id => "1" }
    )

    get "/changeset/1/subscribe"
    assert_redirected_to "/changeset/1/subscription"

    get "/changeset/1/unsubscribe"
    assert_redirected_to "/changeset/1/subscription"
  end

  def test_show_as_anonymous
    changeset = create(:changeset)

    get changeset_subscription_path(changeset)
    assert_redirected_to login_path(:referer => changeset_subscription_path(changeset))
  end

  def test_show_when_not_subscribed
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)

    session_for(other_user)
    get changeset_subscription_path(changeset)

    assert_response :success
    assert_dom ".content-body" do
      assert_dom "a[href='#{changeset_path(changeset)}']", :text => "Changeset #{changeset.id}"
      assert_dom "a[href='#{user_path(user)}']", :text => user.display_name
      assert_dom "form" do
        assert_dom "> @action", changeset_subscription_path(changeset)
        assert_dom "input[type=submit]" do
          assert_dom "> @value", "Subscribe to discussion"
        end
      end
    end
  end

  def test_show_when_subscribed
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)
    changeset.subscribers << other_user

    session_for(other_user)
    get changeset_subscription_path(changeset)

    assert_response :success
    assert_dom ".content-body" do
      assert_dom "a[href='#{changeset_path(changeset)}']", :text => "Changeset #{changeset.id}"
      assert_dom "a[href='#{user_path(user)}']", :text => user.display_name
      assert_dom "form" do
        assert_dom "> @action", changeset_subscription_path(changeset)
        assert_dom "input[type=submit]" do
          assert_dom "> @value", "Unsubscribe from discussion"
        end
      end
    end
  end

  def test_create_success
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)

    session_for(other_user)
    assert_difference "changeset.subscribers.count", 1 do
      post changeset_subscription_path(changeset)
    end
    assert_redirected_to changeset_path(changeset)
    assert changeset.reload.subscribed?(other_user)
  end

  def test_create_fail
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)
    changeset.subscribers << other_user

    # not signed in
    assert_no_difference "changeset.subscribers.count" do
      post changeset_subscription_path(changeset)
    end
    assert_response :forbidden

    session_for(other_user)

    # bad diary id
    post changeset_subscription_path(999111)
    assert_response :not_found

    # trying to subscribe when already subscribed
    assert_no_difference "changeset.subscribers.count" do
      post changeset_subscription_path(changeset)
    end
  end

  def test_destroy_success
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)
    changeset.subscribers << other_user

    session_for(other_user)
    assert_difference "changeset.subscribers.count", -1 do
      delete changeset_subscription_path(changeset)
    end
    assert_redirected_to changeset_path(changeset)
    assert_not changeset.reload.subscribed?(other_user)
  end

  def test_unsubscribe_fail
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)

    # not signed in
    assert_no_difference "changeset.subscribers.count" do
      delete changeset_subscription_path(changeset)
    end
    assert_response :forbidden

    session_for(other_user)

    # bad diary id
    delete changeset_subscription_path(999111)
    assert_response :not_found

    # trying to unsubscribe when not subscribed
    assert_no_difference "changeset.subscribers.count" do
      delete changeset_subscription_path(changeset)
    end
  end
end
