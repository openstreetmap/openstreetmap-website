class AddAuthorAndBodyToNotes < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      change_table :notes, :bulk => true do |t|
        t.column :author_id, :bigint, :null => true
        t.column :author_ip, :inet, :null => true
        t.column :body, :text, :null => true
      end

      # TODO: Should this happen in a migration or within e.g. a rake task in
      # which we can perform some sanity checks and which runs in the background.
      # reversible do |dir|
      #   dir.up do
      #     execute <<-SQL.squish
      #     UPDATE
      #       notes
      #     SET
      #       body = c.body,
      #       author_id = c.author_id,
      #       author_ip = c.author_ip
      #     FROM
      #       note_comments c
      #     WHERE
      #       notes.id = c.note_id
      #       AND c.event = 'opened';
      #     SQL
      #   end
      # end
    end

    add_foreign_key :notes, :users, :column => :author_id, :validate => false
  end
end
