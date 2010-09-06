class SpamObserver < ActiveRecord::Observer
  observe User, DiaryEntry, DiaryComment

  def after_save(record)
    case
    when record.is_a?(User): user = record
    when record.is_a?(DiaryEntry): user = record.user
    when record.is_a?(DiaryComment): user = record.user
    end

    if user.status == "active" and user.spam_score > SPAM_THRESHOLD
      user.update_attributes(:status => "suspended")
    end
  end
end
