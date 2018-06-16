module IssuesHelper
  def reportable_url(reportable)
    case reportable
    when DiaryEntry
      url_for(:controller => reportable.class.name.underscore, :action => :view, :display_name => reportable.user.display_name, :id => reportable.id)
    when User
      url_for(:controller => reportable.class.name.underscore, :action => :view, :display_name => reportable.display_name)
    when DiaryComment
      url_for(:controller => reportable.diary_entry.class.name.underscore, :action => :view, :display_name => reportable.diary_entry.user.display_name, :id => reportable.diary_entry.id, :anchor => "comment#{reportable.id}")
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
    count = Issue.open.limit(100).size
    if count > 99
      content_tag(:span, "99+", :class => "count-number")
    elsif count > 0
      content_tag(:span, count, :class => "count-number")
    end
  end
end
