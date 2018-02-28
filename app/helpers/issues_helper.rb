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
      "#{reportable.diary_entry.title}, Comment id ##{reportable.id}"
    when Note
      "Note ##{reportable.id}"
    end
  end
end
