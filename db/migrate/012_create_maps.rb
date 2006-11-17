class CreateMaps < ActiveRecord::Migration
  def self.up
    create_table :maps do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :maps
  end
end
