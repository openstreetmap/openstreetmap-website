class AddIndexesForIssues < ActiveRecord::Migration
	def self.up
    add_index :issues, :user_id
    add_index :issues, [:reportable_id, :reportable_type]
    add_index :reports, :issue_id
    add_index :reports, :user_id
  	add_index :issue_comments, :user_id
  	add_index :issue_comments, :issue_id
  end

  def self.down
    remove_index :issues, :user_id
    remove_index :issues, [:reportable_id, :reportable_type]
    remove_index :reports, :issue_id
    remove_index :reports, :user_id
  	remove_index :issue_comments, :user_id
  	remove_index :issue_comments, :issue_id
  end
end
