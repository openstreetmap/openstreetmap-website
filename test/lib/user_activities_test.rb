require "test_helper"

class UserActivitiesTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
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
    assert first_day["activity_groups"]

    # Second day should have activities
    second_day = activities[1]
    assert second_day["activity_date"]
    assert second_day["activity_groups"]

    # Check that we have the right number of activities per day
    first_day_count = JSON.parse(first_day["activity_groups"]).values.sum { |g| g["count"] }
    second_day_count = JSON.parse(second_day["activity_groups"]).values.sum { |g| g["count"] }
    assert_equal 2, first_day_count
    assert_equal 2, second_day_count
  end

  def test_for_user_respects_limit_and_offset
    # Create activities across three days
    create(:changeset, :user => @user, :created_at => 3.days.ago)
    create(:diary_entry, :user => @user, :created_at => 2.days.ago)
    create(:note_comment, :author => @user, :created_at => 1.day.ago)

    # Get first page
    activities = UserActivities.for_user(@user.id, :limit => 2, :offset => 0)
    assert_equal 2, activities.length

    # Get second page
    activities = UserActivities.for_user(@user.id, :limit => 2, :offset => 2)
    assert_equal 1, activities.length
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
      groups = JSON.parse(day["activity_groups"])
      groups.each_value do |group|
        items = group["items"].is_a?(String) ? JSON.parse(group["items"]) : group["items"]
        all_items.concat(items)
      end
    end

    # Check that each activity type is present
    assert(all_items.any? { |i| i["reference_id"] == changeset.id })
    assert(all_items.any? { |i| i["reference_id"] == diary.id })
    assert(all_items.any? { |i| i["reference_id"] == note.note_id })
    assert(all_items.any? { |i| i["reference_id"] == gpx.id })
    assert(all_items.any? { |i| i["reference_id"] == diary_comment.diary_entry_id })
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
      groups = JSON.parse(day["activity_groups"])
      groups.each_value do |group|
        items = group["items"].is_a?(String) ? JSON.parse(group["items"]) : group["items"]
        all_items.concat(items)
      end
    end

    # Should only include visible items
    assert_equal 2, all_items.length
  end
end
