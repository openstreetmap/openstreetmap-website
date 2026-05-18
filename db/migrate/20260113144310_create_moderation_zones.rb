# frozen_string_literal: true

class CreateModerationZones < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_zones do |t|
      t.string :name, :null => false
      t.string :reason, :null => false
      t.column :reason_format, :format_enum, :default => "markdown"
      t.st_polygon :zone, :srid => 4326, :null => false
      t.datetime :ends_at

      t.references :creator, :null => false, :foreign_key => { :to_table => :users }
      t.references :revoker, :foreign_key => { :to_table => :users }

      t.timestamps
    end
  end
end
