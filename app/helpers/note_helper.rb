module NoteHelper
  include ActionView::Helpers::TranslationHelper

  def note_description(author, description, first_comment)
    if !author.nil? && author.status == "deleted"
      RichText.new("text", t("notes.show.description_when_author_is_deleted"))
    elsif first_comment&.event != "opened"
      RichText.new("text", t("notes.show.description_when_there_is_no_opening_comment"))
    else
      description
    end
  end

  def note_event(event, at, by)
    if by.nil?
      t("notes.show.event_#{event}_by_anonymous_html",
        :time_ago => friendly_date_ago(at))
    else
      t("notes.show.event_#{event}_by_html",
        :time_ago => friendly_date_ago(at),
        :user => note_author(by))
    end
  end

  def note_author(author, link_options = {})
    if author.nil?
      ""
    elsif author.status == "deleted"
      t("users.no_such_user.deleted")
    else
      link_to h(author.display_name), link_options.merge(:controller => "/users", :action => "show", :display_name => author.display_name),
              :class => "mw-100 d-inline-block align-bottom text-truncate text-wrap", :dir => "auto"
    end
  end
end
