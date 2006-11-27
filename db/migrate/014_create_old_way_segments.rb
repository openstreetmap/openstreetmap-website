class CreateOldWaySegments < ActiveRecord::Migration
  def self.up
    create_table :old_way_segments do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :old_way_segments
  end
end
