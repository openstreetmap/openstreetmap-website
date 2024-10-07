class Note < ApplicationRecord
  class MigrateFirstComment
    def initialize(note)
      @note = note
    end

    def call
      return false if skip?

      attributes = first_comment.attributes.slice(*%w[body author_id author_ip]).compact_blank
      @note.update_columns(attributes) # rubocop:disable Rails/SkipsModelValidations
    end

    def skip?
      first_comment.blank?
    end

    private

    def first_comment
      NoteComment.order(:id => :asc).find_by(:note => @note)
    end
  end
end
