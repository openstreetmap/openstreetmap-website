require "migrate"

class CreateRedactions < ActiveRecord::Migration[4.2]
  def change
    create_table :redactions do |t|
      t.string :title
      t.text :description

      t.timestamps :null => true
    end

    [:nodes, :ways, :relations].each do |tbl|
      add_column tbl, :redaction_id, :integer, :null => true
      add_foreign_key tbl, :redactions, :name => "#{tbl}_redaction_id_fkey"
    end
  end
end
