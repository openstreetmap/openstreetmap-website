# frozen_string_literal: true

require "test_helper"

class ModerationZoneTest < ActiveSupport::TestCase
  def test_falls_within_any_active
    create(:moderation_zone, :seville_cathedral, :ends_at => 1.day.from_now)

    dead_center = { :lat => 37.385972, :lon => -5.993149 }

    assert ModerationZone.falls_within_any_active?(**dead_center)

    # Inside, near the boundary
    assert ModerationZone.falls_within_any_active?(:lat => 37.386658, :lon => -5.994024)

    # Outside, near the boundary
    assert_not ModerationZone.falls_within_any_active?(:lat => 37.386769, :lon => -5.994185)

    travel_to 2.days.from_now do
      assert_not ModerationZone.falls_within_any_active?(**dead_center)
    end
  end

  def test_active?
    modzone1 = create(:moderation_zone, :ends_at => 1.day.from_now)
    assert_predicate modzone1, :active?

    modzone2 = create(:moderation_zone, :ends_at => 1.day.ago)
    assert_not_predicate modzone2, :active?
  end

  def test_round_to_closest_minute
    assert_equal Time.utc(2026, 1, 1, 12, 30, 0), ModerationZone.round_to_closest_minute(Time.utc(2026, 1, 1, 12, 30, 29))
    assert_equal Time.utc(2026, 1, 1, 12, 31, 0), ModerationZone.round_to_closest_minute(Time.utc(2026, 1, 1, 12, 30, 31))
    assert_equal Time.utc(2026, 1, 1, 12, 30, 0), ModerationZone.round_to_closest_minute(Time.utc(2026, 1, 1, 12, 30, 0))
  end

  def test_round_to_next_minute
    assert_equal Time.utc(2026, 1, 1, 12, 31, 0), ModerationZone.round_to_next_minute(Time.utc(2026, 1, 1, 12, 30, 1))
    assert_equal Time.utc(2026, 1, 1, 12, 30, 0), ModerationZone.round_to_next_minute(Time.utc(2026, 1, 1, 12, 30, 0))
  end
end
