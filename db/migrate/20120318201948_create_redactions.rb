require 'migrate'

class CreateRedactions < ActiveRecord::Migration
  def up
    create_table :redactions do |t|
      t.column :user_id, :bigint, :null => false
      t.string :title
      t.text :description
      t.column :description_format, :format_enum, :null => false, :default => "html"

      t.timestamps
    end

    [:nodes, :ways, :relations].each do |tbl|
      add_column tbl, :redaction_id, :bigint, :null => true
      add_foreign_key tbl, [:redaction_id], :redactions, [:id]
    end
  end

  def down
    [:nodes, :ways, :relations].each do |tbl|
      remove_foreign_key tbl, [:redaction_id], :redactions, [:id]
      remove_column tbl, :redaction_id
    end
    
    drop_table :redactions
  end
end
