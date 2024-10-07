class Note < ApplicationRecord
  # NB: Copies the body, author and author_ip from the give Note-records first comment to the author.
  # If the copy-process was succesful, the first comment will be removed from the database.
  class MigrateFirstComment
    def initialize(note)
      @note = note
      @first_comment = NoteComment.order(:id => :asc).find_by(:note => @note)
      @first_comment_attributes = (@first_comment&.attributes || {}).slice(*%w[body author_id author_ip]).compact_blank
      @body = @first_comment_attributes["body"]
    end

    def call
      return false if skip?

      @note.with_lock do
        @note.update_columns(@first_comment_attributes) # rubocop:disable Rails/SkipsModelValidations
        @first_comment.destroy!
      end

      true
    end

    def skip?
      @first_comment.blank? || @body.blank?
    end
  end
end
