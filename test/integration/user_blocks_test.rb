require "test_helper"

class UserBlocksTest < ActionDispatch::IntegrationTest
  fixtures :users, :user_roles

  def auth_header(user, pass)
    { "HTTP_AUTHORIZATION" => format("Basic %s", Base64.encode64("#{user}:#{pass}")) }
  end

  def test_api_blocked
    blocked_user = users(:public_user)

    get "/api/#{API_VERSION}/user/details"
    assert_response :unauthorized

    get "/api/#{API_VERSION}/user/details", nil, auth_header(blocked_user.display_name, "test")
    assert_response :success

    # now block the user
    UserBlock.create(
      :user_id => blocked_user.id,
      :creator_id => users(:moderator_user).id,
      :reason => "testing",
      :ends_at => Time.now.getutc + 5.minutes
    )
    get "/api/#{API_VERSION}/user/details", nil, auth_header(blocked_user.display_name, "test")
    assert_response :forbidden
  end

  def test_api_revoke
    blocked_user = users(:public_user)
    moderator = users(:moderator_user)

    block = UserBlock.create(
      :user_id => blocked_user.id,
      :creator_id => moderator.id,
      :reason => "testing",
      :ends_at => Time.now.getutc + 5.minutes
    )
    get "/api/#{API_VERSION}/user/details", nil, auth_header(blocked_user.display_name, "test")
    assert_response :forbidden

    # revoke the ban
    get "/login"
    assert_response :success
    post "/login", "username" => moderator.email, "password" => "test", :referer => "/blocks/#{block.id}/revoke"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/revoke"
    post "/blocks/#{block.id}/revoke", "confirm" => "yes"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
    reset!

    # access the API again. this time it should work
    get "/api/#{API_VERSION}/user/details", nil, auth_header(blocked_user.display_name, "test")
    assert_response :success
  end
end
