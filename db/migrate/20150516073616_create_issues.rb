require "migrate"

class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :reportable_type, :null => false
      t.integer :reportable_id, :null => false
      t.integer :reported_user_id, :null => false
      t.integer :status
      t.datetime :resolved_at
      t.integer :resolved_by
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps null: false
    end

    add_foreign_key :issues, :users, :column => :reported_user_id,:name => "issues_reported_user_id_fkey"

    add_index :issues, :reported_user_id,
    add_index :issues, [:reportable_id, :reportable_type]
    
  end
end
