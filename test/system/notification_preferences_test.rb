# frozen_string_literal: true

require "application_system_test_case"

class NotificationPreferencesTest < ApplicationSystemTestCase
  test "toggling preferences" do
    ActionMailer::Base.deliveries.clear

    user = create(:user)
    sign_in_as(user)

    visit notification_preferences_path

    assert_selector ".notification_preferences input:checked", :count => 7

    follow1 = create(:follow, :following => user)
    perform_enqueued_jobs do
      NewFollowerNotifier.with(:record => follow1).deliver
    end
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal user.email, email.to.first
    ActionMailer::Base.deliveries.clear

    uncheck "user_notification_preferences_new_follower_email"
    uncheck "user_notification_preferences_gpx_import_success_email"
    click_on "Update Preferences"

    assert_selector ".notification_preferences input:checked", :count => 5
    assert_selector "input#user_notification_preferences_new_follower_email:not(checked)"

    follow2 = create(:follow, :following => user)
    perform_enqueued_jobs do
      NewFollowerNotifier.with(:record => follow2).deliver
    end
    assert_empty ActionMailer::Base.deliveries
  end
end
