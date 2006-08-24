class CreateSegments < ActiveRecord::Migration
  def self.up
    create_table :segments do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :segments
  end
end
