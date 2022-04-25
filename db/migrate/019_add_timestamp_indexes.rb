class AddTimestampIndexes < ActiveRecord::Migration[4.2]
  def self.up
    add_index :current_ways, :timestamp, :name => :current_ways_timestamp_idx
    add_index :current_relations, :timestamp, :name => :current_relations_timestamp_idx
  end

  def self.down
    remove_index :current_ways, :name => :current_ways_timestamp_idx
    remove_index :current_relations, :name => :current_relations_timestamp_idx
  end
end
