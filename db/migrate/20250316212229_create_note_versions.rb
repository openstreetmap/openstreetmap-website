class CreateNoteVersions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :notes, :version, :bigint, :null => false, :default => 1

    create_table :note_versions, :primary_key => [:note_id, :version] do |t|
      t.bigint :note_id, :null => false
      t.integer :latitude, :null => false
      t.integer :longitude, :null => false
      t.bigint :tile, :null => false
      t.datetime :timestamp, :null => false
      t.column :status, "public.note_status_enum", :null => false
      t.column :event, "public.note_event_enum", :null => false
      t.text :description, :null => false
      t.bigint :user_id
      t.inet :user_ip
      t.bigint :version, :null => false
      t.integer :redaction_id
      t.bigint :note_comment_id, :null => false
      t.boolean :note_comment_visible, :default => true, :null => false

      t.foreign_key :redactions, :column => :redaction_id, :name => "note_versions_redaction_id_fkey"
    end

    add_index :note_versions, :note_comment_id, :name => "note_versions_note_comment_id_idx", :algorithm => :concurrently
  end
end
