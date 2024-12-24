class BackfillNoteDescriptions < ActiveRecord::Migration[7.2]
  class Note < ApplicationRecord; end
  class NoteComment < ApplicationRecord; end

  disable_ddl_transaction!

  def up
    Note.in_batches(:of => 1000) do |notes|
      note_ids = notes.pluck(:id)
      comments = NoteComment.where(:note_id => note_ids, :event => "opened").group_by(&:note_id)

      values = notes.map do |note|
        first_comment = comments[note.id].first
        user_ip_value = first_comment.author_ip.nil? ? "NULL::inet" : "'#{first_comment.author_ip}'::inet"
        user_id_value = first_comment.author_id.nil? ? "NULL::bigint" : "'#{first_comment.author_id}'::bigint"
        "(#{note.id}, '#{first_comment.body}', #{user_ip_value}, #{user_id_value})"
      end.join(", ")

      sql_query = <<-SQL.squish
        UPDATE notes
        SET description = data.description,
            user_ip = COALESCE(data.user_ip::inet, notes.user_ip),
            user_id = COALESCE(data.user_id::bigint, notes.user_id)
        FROM (VALUES #{values}) AS data(id, description, user_ip, user_id)
        WHERE notes.id = data.id;
      SQL

      ActiveRecord::Base.connection.execute(sql_query)
    end
  end
end
