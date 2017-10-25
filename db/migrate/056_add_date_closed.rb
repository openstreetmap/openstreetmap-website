require "migrate"

class AddDateClosed < ActiveRecord::Migration[5.0]
  def self.up
    add_column :map_bugs, :date_closed, :timestamp
  end

  def self.down
    remove_column :map_bugs, :date_closed
  end
end
