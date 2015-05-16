class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :reportable_type
      t.integer :reportable_id
      t.integer :user_id
      t.integer :status
      t.datetime :resolved_at
      t.integer :resolved_by
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps null: false
    end
  end
end
