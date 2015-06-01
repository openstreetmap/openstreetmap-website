class CreateIssueComments < ActiveRecord::Migration
  def change
    create_table :issue_comments do |t|
      t.integer :issue_id
      t.integer :user_id
      t.text :body
      t.datetime :created_at

      t.timestamps null: false
    end

  	add_foreign_key :issue_comments, :issues, :name => "issue_comments_issue_id_fkey"
  	add_foreign_key :issue_comments, :users, :name => "issue_comments_user_id"

  	add_index :issue_comments, :user_id
  	add_index :issue_comments, :issue_id

  end
end
