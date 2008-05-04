class AddUserPreferenceId < ActiveRecord::Migration
  def self.up
    remove_primary_key 'user_preferences'
    add_column "user_preferences", "id", :bigint, :limit => 64, :null => false
    add_primary_key "user_preferences", ["id"]
    change_column "user_preferences", "id", :bigint, :limit => 64, :null => false, :options => "AUTO_INCREMENT"
    add_index "user_preferences", ["id"], :name => "user_preferences_id_idx"
  end

  def self.down
    remove_index 'user_preferences', 'id'
    remove_column 'user_preferences', 'id'
  end
end
