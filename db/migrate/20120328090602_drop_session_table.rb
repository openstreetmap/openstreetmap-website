require 'migrate'

class DropSessionTable < ActiveRecord::Migration
  def up
    drop_table "sessions"
  end

  def down
    create_table "sessions" do |t|
      t.column "session_id", :string
      t.column "data",       :text
      t.column "created_at", :timestamp
      t.column "updated_at", :timestamp
    end
    add_index "sessions", ["session_id"], :name => "sessions_session_id_idx", :unique => true
  end
end
