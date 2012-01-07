class SpamObserver < ActiveRecord::Observer
  observe User, DiaryEntry, DiaryComment

  def after_save(record)
    case
    when record.is_a?(User) then user = record
    when record.is_a?(DiaryEntry) then user = record.user
    when record.is_a?(DiaryComment) then user = record.user
    end

    if user.status == "active" and user.spam_score > SPAM_THRESHOLD
      user.update_attributes(:status => "suspended")
    end
  end
end
