class CreateTracetags < ActiveRecord::Migration
  def self.up
    create_table :tracetags do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :tracetags
  end
end
