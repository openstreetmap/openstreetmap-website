module NoteHelper
  def note_event(event, at, by)
    if by.nil?
      I18n.t("browse.note." + event + "_by_anonymous",
             :when => friendly_date(at),
             :exact_time => l(at)).html_safe
    else
      I18n.t("browse.note." + event + "_by",
             :when => friendly_date(at),
             :exact_time => l(at),
             :user => note_author(by)).html_safe
    end
  end

  def note_author(author, link_options = {})
    if author.nil?
      ""
    elsif author.status == "deleted"
      t("users.no_such_user.deleted")
    else
      link_to h(author.display_name), link_options.merge(:controller => "users", :action => "show", :display_name => author.display_name)
    end
  end
end
