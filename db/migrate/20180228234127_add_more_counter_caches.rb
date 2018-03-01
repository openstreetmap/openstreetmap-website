class AddMoreCounterCaches < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :notes_count, :integer, :null => false, :default => 0
    add_column :users, :diary_comments_count, :integer, :null => false, :default => 0

    NoteComment.group(:author_id).pluck(:author_id).each do |author_id|
      User.reset_counters(author_id, :notes) unless author_id.nil?
    end

    DiaryComment.group(:user_id).pluck(:user_id).each do |user_id|
      User.reset_counters(user_id, :diary_comments)
    end
  end

  def down
    remove_column :users, :notes_count
    remove_column :users, :diary_comments_count
  end
end
