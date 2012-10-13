require 'migrate'

class RenameBugsToNotes < ActiveRecord::Migration
  def self.up
    rename_enumeration "map_bug_status_enum", "note_status_enum"
    rename_enumeration "map_bug_event_enum", "note_event_enum"

    rename_table :map_bugs, :notes
    rename_index :notes, "map_bugs_pkey", "notes_pkey"
    rename_index :notes, "map_bugs_changed_idx", "notes_updated_at_idx"
    rename_index :notes, "map_bugs_created_idx", "notes_created_at_idx"
    rename_index :notes, "map_bugs_tile_idx", "notes_tile_status_idx"

    remove_foreign_key :map_bug_comment, [:bug_id], :map_bugs, [:id]
    rename_column :map_bug_comment, :author_id, :commenter_id
    remove_foreign_key :map_bug_comment, [:commenter_id], :users, [:id]
    rename_column :map_bug_comment, :commenter_id, :author_id

    rename_table :map_bug_comment, :note_comments
    rename_column :note_comments, :bug_id, :note_id
    rename_index :note_comments, "map_bug_comment_pkey", "note_comments_pkey"
    rename_index :note_comments, "map_bug_comment_id_idx", "note_comments_note_id_idx"

    add_foreign_key :note_comments, [:note_id], :notes, [:id]
    add_foreign_key :note_comments, [:author_id], :users, [:id]
  end

  def self.down
    remove_foreign_key :note_comments, [:author_id], :users, [:id]
    remove_foreign_key :note_comments, [:note_id], :notes, [:id]

    rename_index :note_comments, "note_comments_note_id_idx", "map_bug_comment_id_idx"
    rename_index :notes, "note_comments_pkey", "map_bug_comment_pkey"
    rename_column :note_comments, :note_id, :bug_id
    rename_table :note_comments, :map_bug_comment

    rename_column :map_bug_comment, :author_id, :commenter_id
    add_foreign_key :map_bug_comment, [:commenter_id], :users, [:id]
    rename_column :map_bug_comment, :commenter_id, :author_id
    add_foreign_key :map_bug_comment, [:bug_id], :notes, [:id]

    rename_index :notes, "notes_tile_status_idx", "map_bugs_tile_idx"
    rename_index :notes, "notes_created_at_idx", "map_bugs_created_idx"
    rename_index :notes, "notes_updated_at_idx", "map_bugs_changed_idx"
    rename_index :notes, "notes_pkey", "map_bugs_pkey"
    rename_table :notes, :map_bugs

    rename_enumeration "note_event_enum", "map_bug_event_enum"
    rename_enumeration "note_status_enum", "map_bug_status_enum"
  end
end
