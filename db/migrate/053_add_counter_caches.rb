require 'migrate'

class AddCounterCaches < ActiveRecord::Migration
  def self.up
    add_column :users, :changesets_count, :integer, :null => false, :default => 0
    add_column :users, :traces_count, :integer, :null => false, :default => 0
    # reset cached counts for nominations with comments only
    ids = Set.new

    Changeset.all.each {|c| ids << c.user_id}
    Trace.all.each {|c| ids << c.user_id}

    ids.each do |user_id|
      User.reset_counters(user_id, :changesets)
      User.reset_counters(user_id, :traces)
    end
  end
  def self.down
    remove_column :users, :changesets_count
    remove_column :users, :traces_count
  end
end
