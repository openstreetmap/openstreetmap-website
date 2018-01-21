class AddCounterCaches < ActiveRecord::Migration[5.0]
  def self.up
    add_column :users, :changesets_count, :integer, :null => false, :default => 0
    add_column :users, :traces_count, :integer, :null => false, :default => 0

    Changeset.group(:user_id).pluck(:user_id).each do |user_id|
      User.reset_counters(user_id, :changesets)
    end

    Trace.group(:user_id).pluck(:user_id).each do |user_id|
      User.reset_counters(user_id, :traces)
    end
  end

  def self.down
    remove_column :users, :changesets_count
    remove_column :users, :traces_count
  end
end
