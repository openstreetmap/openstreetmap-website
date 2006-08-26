class CreateWays < ActiveRecord::Migration
  def self.up
    create_table :ways do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :ways
  end
end
