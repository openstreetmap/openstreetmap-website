class Note < ApplicationRecord
  class MigrateOpenedComment
    def initialize(note)
      @note = note
    end

    def call
      return false if skip?

      attributes = opened_comment_note.attributes.slice(*%w[body author_id author_ip]).compact_blank
      @note.update_columns(attributes) # rubocop:disable Rails/SkipsModelValidations
    end

    def skip?
      opened_comment_note.blank?
    end

    private

    def opened_comment_note
      @note.comments.unscope(:where => :visible).find_by(:event => "opened")
    end
  end
end
