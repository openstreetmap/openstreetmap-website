require 'migrate'

class CreateRedactions < ActiveRecord::Migration
  def up
    create_table :redactions do |t|
      t.string :title
      t.text :description

      t.timestamps
    end

    [:nodes, :ways, :relations].each do |tbl|
      add_column tbl, :redaction_id, :integer, :null => true
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
