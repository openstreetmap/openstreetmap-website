require "migrate"

class AddMapBugTables < ActiveRecord::Migration
  def self.up
    create_enumeration :map_bug_status_enum, %w(open closed hidden)

    create_table :map_bugs do |t|
      t.integer :latitude, :null => false
      t.integer :longitude, :null => false
      t.column :tile, :bigint, :null => false
      t.datetime :last_changed, :null => false
      t.datetime :date_created, :null => false
      t.string :nearby_place
      t.column :status, :map_bug_status_enum, :null => false
      t.column :date_closed, :timestamp
    end


    change_column :map_bugs, :id, :bigint

    add_index :map_bugs, [:tile, :status], :name => "map_bugs_tile_idx"
    add_index :map_bugs, [:last_changed], :name => "map_bugs_changed_idx"
    add_index :map_bugs, [:date_created], :name => "map_bugs_created_idx"

    create_enumeration :map_bug_event_enum, %w(opened closed reopened commented hidden)


   create_table :map_bug_comment do |t|
      t.column :bug_id, :bigint, :null => false
      t.boolean :visible, :null => false
      t.datetime :date_created, :null => false
      t.string :commenter_name
      t.string :commenter_ip
      t.column :commenter_id, :bigint
      t.column :comment, :text
      t.column :event, :map_bug_event_enum
    end


 
    change_column :map_bug_comment, :id, :bigint


    add_index :map_bug_comment, [:bug_id], :name => "map_bug_comment_id_idx"

    add_foreign_key :map_bug_comment, :map_bugs, :column => :bug_id, :name => "note_comments_note_id_fkey"
    add_foreign_key :map_bug_comment, :users, :column => :commenter_id, :name => "note_comments_author_id_fkey"
  end

  def self.down
    remove_index :map_bugs, :name => "map_bugs_tile_idx"
    remove_index :map_bugs, :name => "map_bugs_changed_idx"
    remove_index :map_bugs, :name => "map_bugs_created_idx"

    drop_table :map_bugs

    drop_enumeration :map_bug_status_enum
  end
end
