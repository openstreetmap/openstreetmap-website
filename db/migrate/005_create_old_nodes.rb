class CreateOldNodes < ActiveRecord::Migration
  def self.up
    create_table :old_nodes do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :old_nodes
  end
end
