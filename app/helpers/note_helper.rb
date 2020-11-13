module NoteHelper
  include ActionView::Helpers::TranslationHelper

  def note_event(event, at, by)
    if by.nil?
      t("browse.note.#{event}_by_anonymous_html",
        :when => friendly_date_ago(at),
        :exact_time => l(at))
    else
      t("browse.note.#{event}_by_html",
        :when => friendly_date_ago(at),
        :exact_time => l(at),
        :user => note_author(by))
    end
  end

  def note_author(author, link_options = {})
    if author.nil?
      ""
    elsif author.status == "deleted"
      t("users.no_such_user.deleted")
    else
      link_to h(author.display_name), link_options.merge(:controller => "/users", :action => "show", :display_name => author.display_name)
    end
  end
end
