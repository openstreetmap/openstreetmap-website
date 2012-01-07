require 'migrate'

class DiaryComments < ActiveRecord::Migration
  def self.up
    create_table "diary_comments", myisam_table do |t|
      t.column "id",             :bigint_pk,              :null => false
      t.column "diary_entry_id", :bigint,   :limit => 20, :null => false
      t.column "user_id",        :bigint,   :limit => 20, :null => false
      t.column "body",           :text,                   :null => false
      t.column "created_at",     :datetime,               :null => false
      t.column "updated_at",     :datetime,               :null => false
    end

    add_index "diary_comments", ["diary_entry_id", "id"], :name => "diary_comments_entry_id_idx", :unique => true

  end

  def self.down
    drop_table "diary_comments"
  end
end
