# frozen_string_literal: true

module HeaderHelper
  def notifications_count(which = :all)
    which = [:messages, :notifications] if which == :all
    which = Array.wrap(which)

    total = 0
    total += current_user.new_messages.size if which.include?(:messages)
    total += current_user.web_notifications.unread.size if which.include?(:notifications)
    total
  end
end
