require "migrate"

class CreateRedactions < ActiveRecord::Migration
  def change
    create_table :redactions do |t|
      t.string :title
      t.text :description

      t.timestamps
    end

    [:nodes, :ways, :relations].each do |tbl|
      add_column tbl, :redaction_id, :integer, :null => true
      add_foreign_key tbl, :redactions, :name => "#{tbl}_redaction_id_fkey"
    end
  end
end
