# frozen_string_literal: true

require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "Profile badge count" do
    user = create(:user)

    # There should be two notifications from changeset comments
    create(:changeset_comment_notification, :recipient => user)
    create(:changeset_comment_notification, :recipient => user)

    # There should be one notification from a direct message
    create(:message, :recipient => user)

    sign_in_as(user)

    find(".user-menu.dropdown [data-bs-toggle]").click
    assert_selector ".badge-user-total", :text => 3
    assert_selector ".badge-user-messages", :text => 1
    assert_selector ".badge-user-notifications", :text => 2
  end
end
