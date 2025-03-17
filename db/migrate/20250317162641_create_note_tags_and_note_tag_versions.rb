class CreateNoteTagsAndNoteTagVersions < ActiveRecord::Migration[7.2]
  def change
    # Create a table, primary and foreign keys for note_tags
    create_table :note_tags, :primary_key => [:note_id, :k] do |t|
      t.column "note_id", :bigint, :null => false
      t.column "k", :string, :null => false
      t.column "v", :string, :null => false

      t.foreign_key :notes, :column => :note_id, :name => "note_tags_id_fkey"
    end

    # Create a table, primary and foreign keys for note_tag_versions
    create_table :note_tag_versions, :primary_key => [:note_id, :version, :k] do |t|
      t.column "note_id", :bigint, :null => false
      t.bigint "version", :null => false, :default => 1
      t.column "k", :string, :null => false
      t.column "v", :string, :null => false

      t.foreign_key :note_versions, :column => [:note_id, :version], :primary_key => [:note_id, :version], :name => "note_tag_versions_id_fkey"
    end
  end
end
