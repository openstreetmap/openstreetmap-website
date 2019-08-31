require "migrate"

class CreateIssuesAndReports < ActiveRecord::Migration[5.0]
  def up
    create_enumeration :issue_status_enum, %w[open ignored resolved]

    create_table :issues do |t|
      t.string :reportable_type, :null => false
      t.integer :reportable_id, :null => false
      t.integer :reported_user_id
      t.column :status, :issue_status_enum, :null => false, :default => "open"
      t.column :assigned_role, :user_role_enum, :null => false
      t.datetime :resolved_at
      t.integer :resolved_by
      t.integer :updated_by
      t.integer :reports_count, :default => 0
      t.timestamps :null => false
    end

    add_foreign_key :issues, :users, :column => :reported_user_id, :name => "issues_reported_user_id_fkey"
    add_foreign_key :issues, :users, :column => :resolved_by, :name => "issues_resolved_by_fkey"
    add_foreign_key :issues, :users, :column => :updated_by, :name => "issues_updated_by_fkey"

    add_index :issues, [:reportable_type, :reportable_id]
    add_index :issues, [:reported_user_id]
    add_index :issues, [:status]
    add_index :issues, [:assigned_role]
    add_index :issues, [:updated_by]

    create_table :reports do |t|
      t.integer :issue_id, :null => false
      t.integer :user_id, :null => false
      t.text :details, :null => false
      t.string :category, :null => false
      t.timestamps :null => false
    end

    add_foreign_key :reports, :issues, :name => "reports_issue_id_fkey"
    add_foreign_key :reports, :users, :column => :user_id, :name => "reports_user_id_fkey"

    add_index :reports, :issue_id
    add_index :reports, :user_id

    create_table :issue_comments do |t|
      t.integer :issue_id, :null => false
      t.integer :user_id, :null => false
      t.text :body, :null => false
      t.timestamps :null => false
    end

    add_foreign_key :issue_comments, :issues, :name => "issue_comments_issue_id_fkey"
    add_foreign_key :issue_comments, :users, :column => :user_id, :name => "issue_comments_user_id_fkey"

    add_index :issue_comments, :issue_id
    add_index :issue_comments, :user_id
  end

  def down
    drop_table :issue_comments
    drop_table :reports
    drop_table :issues
    drop_enumeration :issue_status_enum
  end
end
