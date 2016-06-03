require "migrate"

class CreateDiaryComments < ActiveRecord::Migration
  def self.up
    create_table "diary_comments", :id => false do |t|
      t.column "id",             :bigserial, :primary_key => true, :null => false
      t.column "diary_entry_id", :bigint, :null => false
      t.column "user_id",        :bigint, :null => false
      t.column "body",           :text, :null => false
      t.column "created_at",     :datetime, :null => false
      t.column "updated_at",     :datetime, :null => false
      t.column :visible, :boolean, :null => false, :default => true

    end

    add_index "diary_comments", %w(diary_entry_id id), :name => "diary_comments_entry_id_idx", :unique => true
    add_index :diary_comments, [:user_id, :created_at], :name => "diary_comment_user_id_created_at_index"

  end

  def self.down
    drop_table "diary_comments"
  end
end
