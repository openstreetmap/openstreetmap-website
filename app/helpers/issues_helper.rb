module IssuesHelper
  def reportable_url(reportable)
    case reportable
    when DiaryEntry
      diary_entry_url(reportable.user, reportable)
    when User
      user_url(reportable)
    when DiaryComment
      diary_entry_url(reportable.diary_entry.user, reportable.diary_entry, :anchor => "comment#{reportable.id}")
    when Note
      url_for(:controller => :browse, :action => :note, :id => reportable.id)
    end
  end

  def reportable_title(reportable)
    case reportable
    when DiaryEntry
      reportable.title
    when User
      reportable.display_name
    when DiaryComment
      I18n.t("issues.helper.reportable_title.diary_comment", :entry_title => reportable.diary_entry.title, :comment_id => reportable.id)
    when Note
      I18n.t("issues.helper.reportable_title.note", :note_id => reportable.id)
    end
  end

  def open_issues_count
    count = Issue.visible_to(current_user).open.limit(100).size
    if count > 99
      content_tag(:span, "99+", :class => "count-number")
    elsif count.positive?
      content_tag(:span, count, :class => "count-number")
    end
  end
end
