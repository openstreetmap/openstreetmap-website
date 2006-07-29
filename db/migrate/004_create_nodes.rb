class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :nodes
  end
end
