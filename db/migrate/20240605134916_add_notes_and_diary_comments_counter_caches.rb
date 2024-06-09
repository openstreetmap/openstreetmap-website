class AddNotesAndDiaryCommentsCounterCaches < ActiveRecord::Migration[7.1]
  def self.up
    add_column :users, :diary_comments_count, :integer, :default => 0
    add_column :users, :note_comments_count, :integer, :default => 0

    users_with_diary_comments = DiaryComment.distinct.pluck(:user_id)
    users_with_diary_comments.each do |user_id|
      User.reset_counters(user_id, :diary_comments)
    end

    users_with_note_comments = NoteComment.where.not(:author_id => nil).distinct.pluck(:author_id)
    users_with_note_comments.each do |author_id|
      User.reset_counters(author_id, :note_comments)
    end
  end

  def self.down
    remove_column :users, :diary_comments_count
    remove_column :users, :note_comments_count
  end
end
