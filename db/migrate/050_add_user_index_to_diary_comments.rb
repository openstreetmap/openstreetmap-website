class AddUserIndexToDiaryComments < ActiveRecord::Migration[4.2]
  def self.up
    add_index :diary_comments, [:user_id, :created_at], :name => "diary_comment_user_id_created_at_index"
  end

  def self.down
    remove_index :diary_comments, :name => "diary_comment_user_id_created_at_index"
  end
end
