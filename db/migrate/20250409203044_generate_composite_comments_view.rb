class GenerateCompositeCommentsView < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      execute <<-SQL.squish
        CREATE OR REPLACE VIEW composite_note_comments AS
        SELECT
            COALESCE(note_version.note_comment_id, note_comment.id) AS id,
            COALESCE(note_version.note_id, note_comment.note_id) AS note_id,
            COALESCE(note_comment.visible, true) AS visible,
            COALESCE(note_version.timestamp, note_comment.created_at) AS created_at,
            COALESCE(note_version.user_ip, note_comment.author_ip) AS author_ip,
            COALESCE(note_version.user_id, note_comment.author_id) AS author_id,
            COALESCE(note_comment.body, '') AS body,
            COALESCE(note_version.event, note_comment.event) AS event
        FROM
            note_comments note_comment
        FULL OUTER JOIN
            note_versions note_version
        ON
            note_comment.id = note_version.note_comment_id;
      SQL
    end
  end

  def down
    execute <<-SQL.squish
      DROP VIEW composite_note_comments;
    SQL
  end
end
