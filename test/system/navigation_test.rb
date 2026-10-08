# frozen_string_literal: true

require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "Profile badge count" do
    user = create(:user)

    # There should be two notifications from changeset comments
    create(:changeset_comment_notification, :recipient => user)
    create(:changeset_comment_notification, :recipient => user)
    create(:changeset_comment_notification, :recipient => user, :read_at => Time.zone.now)

    # There should be one notification from a direct message
    create(:message, :recipient => user)

    # Not linked to the actual message above, but it doesn't
    # matter. The important bit is that this notification
    # should not be counted.
    create(:direct_message_notification, :recipient => user)

    sign_in_as(user)

    find(".user-menu.dropdown [data-bs-toggle]").click
    assert_selector ".badge-user-total", :text => 3
    assert_selector ".badge-user-messages", :text => 1
    assert_selector ".badge-user-notifications", :text => 2
  end
end
