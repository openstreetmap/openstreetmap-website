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
      note_url(reportable)
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

  def reportable_heading(reportable)
    heading_params = { :title => link_to(reportable_title(reportable), reportable_url(reportable)) }
    heading_params[:datetime_created] = reportable_heading_time(reportable.created_at)
    heading_params[:datetime_updated] = reportable_heading_time(reportable.updated_at) unless reportable.is_a? User

    case reportable
    when DiaryComment
      t "issues.helper.reportable_heading.diary_comment_html", **heading_params
    when DiaryEntry
      t "issues.helper.reportable_heading.diary_entry_html", **heading_params
    when Note
      t "issues.helper.reportable_heading.note_html", **heading_params
    when User
      t "issues.helper.reportable_heading.user_html", **heading_params
    end
  end

  def open_issues_count
    count = Issue.visible_to(current_user).open.limit(Settings.max_issues_count).size
    if count >= Settings.max_issues_count
      tag.span(I18n.t("count.at_least_pattern", :count => Settings.max_issues_count), :class => "badge count-number")
    elsif count.positive?
      tag.span(count, :class => "badge count-number")
    end
  end

  private

  def reportable_heading_time(datetime)
    tag.time l(datetime.to_datetime, :format => :friendly), :datetime => datetime.xmlschema
  end
end
