require 'migrate'

class SqlSessionStoreSetup < ActiveRecord::Migration
  def self.up
    create_table "sessions", :options => innodb_option do |t|
      t.column "session_id", :string
      t.column "data",       :text
      t.column "created_at", :timestamp
      t.column "updated_at", :timestamp
    end
    add_index "sessions", ["session_id"], :name => "sessions_session_id_idx", :unique => true
  end

  def self.down
    drop_table "sessions"
  end
end
