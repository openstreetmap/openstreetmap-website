class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.integer :issue_id
      t.integer :user_id
      t.text :details
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps null: false
    end

    add_foreign_key :reports, :issues, :name => "reports_issue_id_fkey"
    add_foreign_key :reports, :users, :name => "reports_user_id_fkey"

    add_index :reports, :issue_id
    add_index :reports, :user_id
        
  end
end
