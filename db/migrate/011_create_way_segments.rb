class CreateWaySegments < ActiveRecord::Migration
  def self.up
    create_table :way_segments do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :way_segments
  end
end
