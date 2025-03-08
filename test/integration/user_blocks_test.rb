require "test_helper"

class UserBlocksTest < ActionDispatch::IntegrationTest
  def test_api_blocked
    blocked_user = create(:user)

    get "/api/#{Settings.api_version}/user/details"
    assert_response :unauthorized

    get "/api/#{Settings.api_version}/user/details", :headers => bearer_authorization_header(blocked_user)
    assert_response :success

    # now block the user
    UserBlock.create(
      :user_id => blocked_user.id,
      :creator_id => create(:moderator_user).id,
      :reason => "testing",
      :ends_at => Time.now.utc + 5.minutes,
      :deactivates_at => Time.now.utc + 5.minutes
    )
    get "/api/#{Settings.api_version}/user/details", :headers => bearer_authorization_header(blocked_user)
    assert_response :forbidden
  end

  def test_api_revoke
    blocked_user = create(:user)
    moderator = create(:moderator_user)

    block = UserBlock.create(
      :user_id => blocked_user.id,
      :creator_id => moderator.id,
      :reason => "testing",
      :ends_at => Time.now.utc + 5.minutes,
      :deactivates_at => Time.now.utc + 5.minutes
    )
    get "/api/#{Settings.api_version}/user/details", :headers => bearer_authorization_header(blocked_user)
    assert_response :forbidden

    # revoke the ban
    get "/login"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    post "/login", :params => { "username" => moderator.email, "password" => "test", :referer => "/user_blocks/#{block.id}/edit" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/edit"
    put "/user_blocks/#{block.id}", :params => { :user_block_period => "0",
                                                 :user_block => { :needs_view => false, :reason => "Unblocked" } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
    reset!

    # access the API again. this time it should work
    get "/api/#{Settings.api_version}/user/details", :headers => bearer_authorization_header(blocked_user)
    assert_response :success
  end
end
