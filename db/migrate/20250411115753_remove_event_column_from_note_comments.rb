class RemoveEventColumnFromNoteComments < ActiveRecord::Migration[8.0]
  def up
    # Update the composite_note_comments view not to use event column
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
            COALESCE(note_version.event, 'commented') AS event
        FROM
            note_comments note_comment
        FULL OUTER JOIN
            note_versions note_version
        ON
            note_comment.id = note_version.note_comment_id;
      SQL
    end

    # Remove the "event" column from the "note_comments" table
    safety_assured { remove_column :note_comments, :event, :note_event_enum }
  end

  def down
    # Add the "event" column to the "note_comments" table
    add_column :note_comments, :event, :note_event_enum

    # Update the composite_note_comments view to use event column
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
end
