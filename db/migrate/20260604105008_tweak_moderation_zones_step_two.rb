# frozen_string_literal: true

class TweakModerationZonesStepTwo < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :moderation_zones, :name => "moderation_zones_ends_at_null"
    change_column_null :moderation_zones, :ends_at, false
    remove_check_constraint :moderation_zones, :name => "moderation_zones_ends_at_null"
  end

  def down
    add_check_constraint :moderation_zones, "ends_at IS NOT NULL", :name => "moderation_zones_ends
_at_null", :validate => false
    change_column_null :moderation_zones, :ends_at, true
  end
end
