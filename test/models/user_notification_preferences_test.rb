# frozen_string_literal: true

require "test_helper"

class UserNotificationPreferencesTest < ActiveSupport::TestCase
  def test_all_enabled_by_default
    preferences = UserNotificationPreferences.new(create(:user))
    assert_equal ["email"], preferences.changeset_comment
    assert_equal ["email"], preferences.diary_comment
    assert_equal ["email"], preferences.direct_message
    assert_equal ["email"], preferences.gpx_import_failure
    assert_equal ["email"], preferences.gpx_import_success
    assert_equal ["email"], preferences.new_follower
    assert_equal ["email"], preferences.note_comment
  end

  def test_update
    preferences = UserNotificationPreferences.new(create(:user))
    preferences.update(
      "changeset_comment" => ["email"],
      "diary_comment" => [],
      "direct_message" => ["email"],
      "gpx_import_failure" => ["email"],
      "gpx_import_success" => nil,
      "new_follower" => []
    )

    assert_equal ["email"], preferences.changeset_comment
    assert_equal [], preferences.diary_comment
    assert_equal ["email"], preferences.direct_message
    assert_equal ["email"], preferences.gpx_import_failure
    assert_equal [], preferences.gpx_import_success
    assert_equal [], preferences.new_follower

    # Default value
    assert_equal ["email"], preferences.note_comment
  end

  def test_update_ignore_invalid_values
    preferences = UserNotificationPreferences.new(create(:user))

    preferences.update("changeset_comment" => ["whatsapp"])
    assert_equal [], preferences.changeset_comment
    assert_equal 0, UserPreference.where("k LIKE '%whatsapp%'").count

    preferences.update("changeset_comment" => %w[whatsapp email])
    assert_equal ["email"], preferences.changeset_comment
    assert_equal 0, UserPreference.where("k LIKE '%whatsapp%'").count

    preferences.update("imaginary_event" => ["email"])
    assert_equal 0, UserPreference.where("k LIKE '%imaginary_event%'").count
  end

  def test_update_ignore_unmentioned_events
    preferences = UserNotificationPreferences.new(create(:user))
    preferences.update(
      "changeset_comment" => ["email"],
      "diary_comment" => []
    )
    assert_equal 1, count_event_preferences_in_db("changeset_comment")
    assert_equal 1, count_event_preferences_in_db("diary_comment")
    assert_equal 0, count_event_preferences_in_db("direct_message")
    assert_equal 0, count_event_preferences_in_db("gpx_import_failure")
    assert_equal 0, count_event_preferences_in_db("gpx_import_success")
    assert_equal 0, count_event_preferences_in_db("new_follower")
    assert_equal 0, count_event_preferences_in_db("note_comment")
    assert_equal 0, count_event_preferences_in_db("note_comment")
  end

  private

  def count_event_preferences_in_db(event_name)
    # A bit paranoid, but want to avoid misspellings, etc that produce
    # false positives.
    raise "Unknown event #{event_name.inspect}" unless UserNotificationPreferences::EVENTS.include?(event_name)

    UserPreference.where("k LIKE 'notification.#{event_name}.%'").count
  end
end
