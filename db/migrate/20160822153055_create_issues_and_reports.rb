require "migrate"

class CreateIssuesAndReports < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :reportable_type, :null => false
      t.integer :reportable_id, :null => false
      t.integer :reported_user_id, :null => false
      t.integer :status
      t.string :issue_type
      t.datetime :resolved_at
      t.integer :resolved_by
      t.integer :updated_by
      t.timestamps :null => false
    end

    add_foreign_key :issues, :users, :column => :reported_user_id, :name => "issues_reported_user_id_fkey", :on_delete => :cascade

    add_index :issues, :reported_user_id
    add_index :issues, [:reportable_id, :reportable_type]

    create_table :reports do |t|
      t.integer :issue_id
      t.integer :reporter_user_id
      t.text :details, :null => false
      t.timestamps :null => false
    end

    add_foreign_key :reports, :issues, :name => "reports_issue_id_fkey", :on_delete => :cascade
    add_foreign_key :reports, :users, :column => :reporter_user_id, :name => "reports_reporter_user_id_fkey", :on_delete => :cascade

    add_index :reports, :reporter_user_id
    add_index :reports, :issue_id
  end
end
