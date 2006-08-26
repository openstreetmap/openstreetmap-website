class CreateOldWays < ActiveRecord::Migration
  def self.up
    create_table :old_ways do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :old_ways
  end
end
