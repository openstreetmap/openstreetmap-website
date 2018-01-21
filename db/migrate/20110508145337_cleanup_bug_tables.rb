class CleanupBugTables < ActiveRecord::Migration[5.0]
  def self.up
    rename_column :map_bugs, :date_created, :created_at
    rename_column :map_bugs, :last_changed, :updated_at
    rename_column :map_bugs, :date_closed, :closed_at

    rename_column :map_bug_comment, :date_created, :created_at
    rename_column :map_bug_comment, :commenter_name, :author_name
    rename_column :map_bug_comment, :commenter_ip, :author_ip
    rename_column :map_bug_comment, :commenter_id, :author_id
    rename_column :map_bug_comment, :comment, :body
  end

  def self.down
    rename_column :map_bug_comment, :body, :comment
    rename_column :map_bug_comment, :author_id, :commenter_id
    rename_column :map_bug_comment, :author_ip, :commenter_ip
    rename_column :map_bug_comment, :author_name, :commenter_name
    rename_column :map_bug_comment, :created_at, :date_created

    rename_column :map_bugs, :closed_at, :date_closed
    rename_column :map_bugs, :updated_at, :last_changed
    rename_column :map_bugs, :created_at, :date_created
  end
end
