require 'lib/migrate'

class RefactorMapBugTables < ActiveRecord::Migration
  def self.up


    create_table :map_bug_comment do |t|
      t.column :id, :bigint, :null => false
	  t.column :bug_id, :bigint, :null => false
      t.boolean :visible, :null => false 
      t.datetime :date_created, :null => false
	  t.string :commenter_name
	  t.string :commenter_ip
	  t.column :commenter_id, :bigint
      t.string :comment
    end

	remove_column :map_bugs, :text 

    add_index :map_bug_comment, [:bug_id], :name => "map_bug_comment_id_idx"
	add_foreign_key :map_bug_comment, [:bug_id], :map_bugs, [:id]
	add_foreign_key :map_bug_comment, [:commenter_id], :users, [:id]

  end

  def self.down

	add_column :map_bugs, :text, :string

    remove_index :map_bugs, :name => "map_bug_comment_id_idx"
	remove_foreign_key :map_bug_comment, [:bug_id]
	remove_foreign_key :map_bug_comment, [:commenter_id]

    drop_table :map_bugs_comment
  end
end
