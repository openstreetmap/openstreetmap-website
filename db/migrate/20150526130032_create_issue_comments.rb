class CreateIssueComments < ActiveRecord::Migration
  def change
    create_table :issue_comments do |t|
      t.integer :issue_id
      t.integer :user_id
      t.text :body
      t.datetime :created_at

      t.timestamps null: false
    end
  end
end
