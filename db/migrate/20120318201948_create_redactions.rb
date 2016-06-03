require "migrate"

class CreateRedactions < ActiveRecord::Migration
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

    add_column :redactions, :user_id, :bigint, :null => false
    add_column :redactions, :description_format, :format_enum, :null => false, :default => "markdown"

    add_foreign_key :redactions, :users, :name => "redactions_user_id_fkey"
 
  end
end
