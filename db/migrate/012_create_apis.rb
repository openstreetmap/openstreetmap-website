class CreateApis < ActiveRecord::Migration
  def self.up
    create_table :apis do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :apis
  end
end
