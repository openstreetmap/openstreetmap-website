require "test_helper"

class UserActivitiesTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @other_user = create(:user)
    # Create a language for diary entries
    Language.create!(:code => "en", :english_name => "English")
  end

  def test_for_user_returns_activities_grouped_by_day
    # Create activities on different days
    create(:changeset, :user => @user, :created_at => 2.days.ago)
    create(:diary_entry, :user => @user, :created_at => 2.days.ago)
    create(:changeset, :user => @user, :created_at => 1.day.ago)
    create(:note_comment, :author => @user, :created_at => 1.day.ago)

    activities = UserActivities.for_user(@user.id)

    assert_equal 2, activities.length # Two days of activities

    # First day should have activities
    first_day = activities[0]
    assert first_day["activity_date"]
    daily_activities = JSON.parse(first_day["daily_activities"])
    assert_predicate daily_activities, :present?

    # Second day should have activities
    second_day = activities[1]
    assert second_day["activity_date"]
    daily_activities = JSON.parse(second_day["daily_activities"])
    assert_predicate daily_activities, :present?

    # Check that we have the right number of activities per day
    first_day_count = JSON.parse(first_day["daily_activities"]).sum { |g| g["count"] }
    second_day_count = JSON.parse(second_day["daily_activities"]).sum { |g| g["count"] }
    assert_equal 2, first_day_count
    assert_equal 2, second_day_count
  end

  def test_for_user_respects_limit_and_cursor
    # Create activities across three days
    create(:changeset, :user => @user, :created_at => 3.days.ago)
    create(:diary_entry, :user => @user, :created_at => 2.days.ago)
    create(:note_comment, :author => @user, :created_at => 1.day.ago)

    # Get first page
    activities = UserActivities.for_user(@user.id, :limit => 2)
    assert_equal 2, activities.length

    # Get next page using cursor
    last_activity_timestamp = activities.last["daily_activities"]
    last_activity = JSON.parse(last_activity_timestamp).first
    last_item = JSON.parse(last_activity["items"]).first
    next_page = UserActivities.for_user(@user.id, :limit => 2, :before => last_item["timestamp"])
    assert_equal 1, next_page.length
  end

  def test_count_activities_returns_number_of_active_days
    create(:changeset, :user => @user, :created_at => 2.days.ago)
    create(:diary_entry, :user => @user, :created_at => 2.days.ago) # Same day
    create(:note_comment, :author => @user, :created_at => 1.day.ago) # Different day

    count = UserActivities.count_activities(@user.id)
    assert_equal 2, count # Should count two distinct days
  end

  def test_activities_include_all_types
    # Create one of each activity type
    changeset = create(:changeset, :user => @user)
    diary = create(:diary_entry, :user => @user)
    note = create(:note_comment, :author => @user)
    gpx = create(:trace, :user => @user)
    diary_comment = create(:diary_comment, :user => @user)

    activities = UserActivities.for_user(@user.id)

    # Extract all items from all activity groups
    all_items = []
    activities.each do |day|
      JSON.parse(day["daily_activities"]).each do |group|
        all_items.concat(JSON.parse(group["items"]))
      end
    end

    # Check that each activity type is present
    assert(all_items.any? { |i| i["reference_id"].to_s == changeset.id.to_s })
    assert(all_items.any? { |i| i["reference_id"].to_s == diary.id.to_s })
    assert(all_items.any? { |i| i["reference_id"].to_s == note.note_id.to_s })
    assert(all_items.any? { |i| i["reference_id"].to_s == gpx.id.to_s })
    assert(all_items.any? { |i| i["reference_id"].to_s == diary_comment.diary_entry_id.to_s })
  end

  def test_activities_respect_visibility
    # Create visible and invisible items
    create(:diary_entry, :user => @user, :visible => true)
    create(:diary_entry, :user => @user, :visible => false)
    create(:diary_comment, :user => @user, :visible => true)
    create(:diary_comment, :user => @user, :visible => false)

    activities = UserActivities.for_user(@user.id)

    # Count all items from all activity groups
    all_items = []
    activities.each do |day|
      JSON.parse(day["daily_activities"]).each do |group|
        all_items.concat(JSON.parse(group["items"]))
      end
    end

    # Should only include visible items
    assert_equal 2, all_items.length
  end

  def test_activities_are_sorted_by_date_descending
    # Create activities on different days
    create(:changeset, :user => @user, :created_at => 3.days.ago)
    create(:diary_entry, :user => @user, :created_at => 2.days.ago)
    create(:note_comment, :author => @user, :created_at => 1.day.ago)

    activities = UserActivities.for_user(@user.id)

    # Check that dates are in descending order
    dates = activities.pluck("activity_date")
    assert_equal dates, dates.sort.reverse
  end

  def test_activities_within_day_are_sorted_by_time_descending
    # Create multiple activities on the same day
    time = Time.current.beginning_of_day
    create(:changeset, :user => @user, :created_at => time + 1.hour)
    create(:changeset, :user => @user, :created_at => time + 2.hours)
    create(:changeset, :user => @user, :created_at => time + 3.hours)

    activities = UserActivities.for_user(@user.id)

    # Get timestamps from the first day's changeset activities
    daily_activities = JSON.parse(activities.first["daily_activities"])
    changeset_group = daily_activities.find { |g| g["category"] == "changeset" }
    timestamps = JSON.parse(changeset_group["items"]).map { |i| Time.zone.parse(i["timestamp"]) }

    # Check that timestamps are in descending order
    assert_equal timestamps, timestamps.sort.reverse
  end
end
