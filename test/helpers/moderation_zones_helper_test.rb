# frozen_string_literal: true

require "test_helper"

class ModerationZonesHelperTest < ActionView::TestCase
  include UserBlocksHelper

  def setup
    @virtual_path = "moderation_zones.form"
  end

  test "options_for_moderation_zone_period excludes 0 on creation" do
    moderation_zone = ModerationZone.new
    options = options_for_moderation_zone_period(moderation_zone)
    assert_not_includes options, revocation_option
  end

  test "options_for_moderation_zone_period includes 0 on update" do
    moderation_zone = create(:moderation_zone)
    options = options_for_moderation_zone_period(moderation_zone)
    assert_includes options, revocation_option
  end

  def revocation_option
    ["Revoke moderation zone", 0]
  end
end
