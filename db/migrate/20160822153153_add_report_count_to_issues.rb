class AddReportCountToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :report_count, :integer, :default => 0
    add_foreign_key :issues, :users, :column => :updated_by, :name => "issues_updated_by_fkey", :on_delete => :cascade
    add_index :issues, :updated_by
  end
end
