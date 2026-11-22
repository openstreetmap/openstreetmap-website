# frozen_string_literal: true

class ChangesetCommentMentionNotifier < ApplicationNotifier
  recipients -> { record.notifiable_mentioned_users }

  validates :record, :presence => true
end
