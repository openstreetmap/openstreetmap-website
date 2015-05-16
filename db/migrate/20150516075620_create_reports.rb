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
  end
end
