class CreateIssueComments < ActiveRecord::Migration
  def change
    create_table :issue_comments do |t|
      t.integer :issue_id
      t.integer :commenter_user_id
      t.text :body
      t.datetime :created_at
      t.boolean :reassign
      t.timestamps null: false
    end

  	add_foreign_key :issue_comments, :issues, :name => "issue_comments_issue_id_fkey", on_delete: :cascade
  	add_foreign_key :issue_comments, :users,:column => :commenter_user_id, :name => "issue_comments_commenter_user_id", on_delete: :cascade

  	add_index :issue_comments, :commenter_user_id
  	add_index :issue_comments, :issue_id

  end
end
