require "migrate"

class AddForeignKeysForIssues < ActiveRecord::Migration
  def change
  	add_foreign_key :issues, :users, :name => "issues_user_id_fkey"
  	add_foreign_key :reports, :issues, :name => "reports_issue_id_fkey"
  	add_foreign_key :reports, :users, :name => "reports_user_id_fkey"
  	add_foreign_key :issue_comments, :issues, :name => "issue_comments_issue_id_fkey"
  	add_foreign_key :issue_comments, :users, :name => "issue_comments_user_id"
  end
end
