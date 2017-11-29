class AddReportsCountToIssues < ActiveRecord::Migration[5.0]
  def change
    add_column :issues, :reports_count, :integer, :default => 0
    add_foreign_key :issues, :users, :column => :updated_by, :name => "issues_updated_by_fkey", :on_delete => :cascade
    add_index :issues, :updated_by
  end
end
