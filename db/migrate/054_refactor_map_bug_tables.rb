require 'migrate'

class RefactorMapBugTables < ActiveRecord::Migration
  def self.up
    create_table :map_bug_comment do |t|
      t.column :bug_id, :bigint, :null => false
      t.boolean :visible, :null => false
      t.datetime :date_created, :null => false
      t.string :commenter_name
      t.string :commenter_ip
      t.column :commenter_id, :bigint
      t.string :comment
    end

    remove_column :map_bugs, :text

    change_column :map_bug_comment, :id, :bigint

    add_index :map_bug_comment, [:bug_id], :name => "map_bug_comment_id_idx"

    add_foreign_key :map_bug_comment, :map_bugs, :column => :bug_id, :name => "note_comments_note_id_fkey"
    add_foreign_key :map_bug_comment, :users, :column => :commenter_id, :name => "note_comments_author_id_fkey"
  end

  def self.down
    remove_foreign_key :map_bug_comment, :users, :column => :commenter_id, :name => "note_comments_author_id_fkey"
    remove_foreign_key :map_bug_comment, :map_bugs, :column => :bug_id, :name => "note_comments_note_id_fkey"

    remove_index :map_bugs, :name => "map_bug_comment_id_idx"

    add_column :map_bugs, :text, :string

    drop_table :map_bug_comment
  end
end
