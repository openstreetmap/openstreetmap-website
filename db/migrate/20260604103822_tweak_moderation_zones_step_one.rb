# frozen_string_literal: true

class TweakModerationZonesStepOne < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :moderation_zones, "ends_at IS NOT NULL", :name => "moderation_zones_ends_at_null", :validate => false
  end
end
