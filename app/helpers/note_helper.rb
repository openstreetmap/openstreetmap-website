module NoteHelper
  def note_event(at, by)
    if by.nil?
      I18n.t("browse.note.at_html", :when => friendly_date(at)).html_safe
    else
      I18n.t("browse.note.at_by_html", :when => friendly_date(at), :user => note_author(by)).html_safe
    end
  end

  def note_author(author, link_options = {})
    if author.nil?
      ""
    else
      link_to h(author.display_name), link_options.merge({:controller => "user", :action => "view", :display_name => author.display_name})
    end
  end
end
