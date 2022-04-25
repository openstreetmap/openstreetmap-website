require "test_helper"

class UserBlocksTest < ActionDispatch::IntegrationTest
  def test_api_blocked
    blocked_user = create(:user)

    get "/api/#{Settings.api_version}/user/details"
    assert_response :unauthorized

    get "/api/#{Settings.api_version}/user/details", :headers => basic_authorization_header(blocked_user.display_name, "test")
    assert_response :success

    # now block the user
    UserBlock.create(
      :user_id => blocked_user.id,
      :creator_id => create(:moderator_user).id,
      :reason => "testing",
      :ends_at => Time.now.utc + 5.minutes
    )
    get "/api/#{Settings.api_version}/user/details", :headers => basic_authorization_header(blocked_user.display_name, "test")
    assert_response :forbidden
  end

  def test_api_revoke
    blocked_user = create(:user)
    moderator = create(:moderator_user)

    block = UserBlock.create(
      :user_id => blocked_user.id,
      :creator_id => moderator.id,
      :reason => "testing",
      :ends_at => Time.now.utc + 5.minutes
    )
    get "/api/#{Settings.api_version}/user/details", :headers => basic_authorization_header(blocked_user.display_name, "test")
    assert_response :forbidden

    # revoke the ban
    get "/login"
    assert_response :success
    post "/login", :params => { "username" => moderator.email, "password" => "test", :referer => "/blocks/#{block.id}/revoke" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/revoke"
    post "/blocks/#{block.id}/revoke", :params => { "confirm" => "yes" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
    reset!

    # access the API again. this time it should work
    get "/api/#{Settings.api_version}/user/details", :headers => basic_authorization_header(blocked_user.display_name, "test")
    assert_response :success
  end
end
