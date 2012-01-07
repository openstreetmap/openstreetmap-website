require 'migrate'

class UserEnhancements < ActiveRecord::Migration
  def self.up
    add_column "diary_entries", "latitude", :double
    add_column "diary_entries", "longitude", :double
    add_column "diary_entries", "language", :string, :limit => 3

    create_table "user_preferences", innodb_table do |t|
      t.column "user_id", :bigint, :limit => 20, :null => false
      t.column "k",       :string, :null => false
      t.column "v",       :string, :null => false
    end

    add_primary_key "user_preferences", ["user_id", "k"]

    create_table "user_tokens", innodb_table do |t|
      t.column "id",      :bigint_pk, :null => false
      t.column "user_id", :bigint,   :limit => 20, :null => false
      t.column "token",   :string,   :null => false
      t.column "expiry",  :datetime, :null => false
    end

    add_index "user_tokens", ["token"], :name => "user_tokens_token_idx", :unique => true
    add_index "user_tokens", ["user_id"], :name => "user_tokens_user_id_idx"

    User.find(:all, :conditions => "token is not null").each do |user|
      UserToken.create(:user_id => user.id, :token => user.token, :expiry => 1.week.from_now)
    end

    remove_column "users", "token"
    remove_column "users", "timeout"
    remove_column "users", "within_lon"
    remove_column "users", "within_lat"
    add_column "users", "nearby", :integer, :default => 50
    add_column "users", "pass_salt", :string

    User.update_all("nearby = 50");
  end

  def self.down
    remove_column "users", "pass_salt"
    remove_column "users", "nearby"
    add_column "users", "within_lat", :double
    add_column "users", "within_lon", :double
    add_column "users", "timeout", :datetime
    add_column "users", "token", :string

    drop_table "user_tokens"

    drop_table "user_preferences"

    remove_column "diary_entries", "language"
    remove_column "diary_entries", "longitude"
    remove_column "diary_entries", "latitude"
  end
end
