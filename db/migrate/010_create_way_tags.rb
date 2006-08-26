class CreateWayTags < ActiveRecord::Migration
  def self.up
    create_table :way_tags do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :way_tags
  end
end
