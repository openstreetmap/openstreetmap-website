# frozen_string_literal: true

require "test_helper"

class ModerationZoneTest < ActiveSupport::TestCase
  def test_falls_within_any
    create(:moderation_zone, :seville_cathedral)

    # Dead center
    assert ModerationZone.falls_within_any?(:lat => 37.385972, :lon => -5.993149)

    # Inside, near the boundary
    assert ModerationZone.falls_within_any?(:lat => 37.386658, :lon => -5.994024)

    # Outside, near the boundary
    assert_not ModerationZone.falls_within_any?(:lat => 37.386769, :lon => -5.994185)
  end
end
