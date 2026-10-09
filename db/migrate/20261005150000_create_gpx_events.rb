# frozen_string_literal: true

class CreateGpxEvents < ActiveRecord::Migration[8.1]
  def change
    create_enum :gpx_event_action_enum, %w[added removed]

    create_table :gpx_events do |t|
      t.bigint :gpx_id, :null => false
      t.column :action, :gpx_event_action_enum, :null => false
      t.datetime :created_at, :null => false

      t.index [:created_at, :id]
    end
  end
end
