# frozen_string_literal: true

class NoteCommentNotifier < ApplicationNotifier
  recipients lambda {
    note = record.note
    note.subscribers.visible.where.not(:id => record.author_id)
  }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "note_comment_notification"
    config.args = -> { [record, recipient] }
  end
end
