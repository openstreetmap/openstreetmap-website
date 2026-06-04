# frozen_string_literal: true

class TweakModerationZonesStepOne < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        safety_assured do
          execute "UPDATE moderation_zones SET ends_at = NOW()"
        end
      end
    end

    add_check_constraint :moderation_zones, "ends_at IS NOT NULL", :name => "moderation_zones_ends_at_null", :validate => false
  end
end
