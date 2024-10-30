class CreateNoteTags < ActiveRecord::Migration[7.2]
  def change
    # Create a table and primary key
    create_table :note_tags, :primary_key => [:note_id, :k] do |t|
      t.column "note_id", :bigint, :null => false
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false
    end

    # Add foreign key without validation
    add_foreign_key :note_tags, :notes, :column => :note_id, :name => "note_tags_id_fkey", :validate => false
  end
end
