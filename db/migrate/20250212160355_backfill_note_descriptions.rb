class BackfillNoteDescriptions < ActiveRecord::Migration[7.2]
  class Note < ApplicationRecord; end
  class NoteComment < ApplicationRecord; end

  disable_ddl_transaction!

  def up
    Note.in_batches(:of => 1000) do |notes|
      note_ids = notes.pluck(:id)

      sql_query = <<-SQL.squish
        WITH first_comment AS(
          SELECT DISTINCT ON (note_id) *
          FROM note_comments
          WHERE note_id BETWEEN #{note_ids.min} AND #{note_ids.max}
          ORDER BY note_id, id
        )
        UPDATE notes
        SET description = first_comment.body,
            user_id = first_comment.author_id,
            user_ip = first_comment.author_ip
        FROM first_comment
        WHERE first_comment.note_id = notes.id
          AND first_comment.event = 'opened';
      SQL

      ActiveRecord::Base.connection.execute(sql_query)
    end
  end
end
