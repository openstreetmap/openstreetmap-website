class CreateTraces < ActiveRecord::Migration
  def self.up
    create_table :traces do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :traces
  end
end
