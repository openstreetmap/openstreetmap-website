class AddUserPreferenceId < ActiveRecord::Migration
  def self.up
    add_column "user_preferences", "id", :bigint, :limit => 64, :null => false, :options => "AUTO_INCREMENT"
    
    add_index "user_preferences", ["id"], :name => "user_preferences_id_idx"
  end

  def self.down
    remove_index 'user_preferences', 'id'
    remove_column 'user_preferences', 'id'
  end
end
