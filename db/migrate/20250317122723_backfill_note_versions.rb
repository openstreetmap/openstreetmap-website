class BackfillNoteVersions < ActiveRecord::Migration[7.2]
  class NoteVersion < ApplicationRecord; end

  class Note < ApplicationRecord
    has_many :note_comments

    def all_comments
      note_comments
    end
  end

  class NoteComment < ApplicationRecord; end

  disable_ddl_transaction!

  def up
    NoteVersion.delete_all

    Note.find_each do |note|
      opening_events = %w[opened reopened]

      version = 1
      note.all_comments.each do |comment|
        if opening_events.include?(comment.event)
          create_note_version_from(note, comment, "open", version)
          version += 1
        elsif comment.event == "closed"
          create_note_version_from(note, comment, "closed", version)
          version += 1
        elsif comment.event == "hidden"
          create_note_version_from(note, comment, "hidden", version)
          version += 1
        end
      end

      if version > 2
        note.version = version - 1
        note.save!
      end
    end
  end

  def down
    NoteVersion.delete_all
  end

  private

  def create_note_version_from(note, comment, status, version)
    NoteVersion.create!(
      :note_id => note.id,
      :latitude => note.latitude,
      :longitude => note.longitude,
      :tile => note.tile,
      :timestamp => comment.created_at,
      :status => status,
      :event => comment.event,
      :description => note.description,
      :user_id => comment.author_id,
      :user_ip => comment.author_ip,
      :version => version,
      :note_comment_id => comment.id
    )
  end
end
