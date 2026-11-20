# frozen_string_literal: true

class AddCommentsEnabledToDiaryEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :diary_entries, :comments_enabled, :boolean, :default => true, :null => false
  end
end
