module ChangesetsHelper
  def changeset_user_link(changeset)
    if changeset.user.status == "deleted"
      t("users.no_such_user.deleted")
    elsif changeset.user.data_public?
      link_to changeset.user.display_name, changeset.user
    else
      t("browse.anonymous")
    end
  end

  def changeset_user_history_link(changeset)
    if changeset.user.status == "deleted"
      link_to(t("users.no_such_user.deleted"), user_history_path(changeset.user))
    elsif changeset.user.data_public?
      link_to(tag.bdi(changeset.user.display_name), user_history_path(changeset.user))
    else
      t("browse.anonymous")
    end
  end

  def changeset_details(changeset)
    if changeset.closed_at > Time.now.utc
      action = :created
      time = time_ago_in_words(changeset.created_at, :scope => :"datetime.distance_in_words_ago")
      title = l(changeset.created_at)
      datetime = changeset.created_at.xmlschema
    else
      action = :closed
      time = time_ago_in_words(changeset.closed_at, :scope => :"datetime.distance_in_words_ago")
      title = safe_join([t("changesets.show.created", :when => l(changeset.created_at)), "&#10;".html_safe, t("changesets.show.closed", :when => l(changeset.closed_at))])
      datetime = changeset.closed_at.xmlschema
    end

    if params.key?(:display_name)
      t "changesets.show.#{action}_ago_html", :time_ago => tag.time(time, :title => title, :datetime => datetime)
    else
      t "changesets.show.#{action}_ago_by_html", :time_ago => tag.time(time, :title => title, :datetime => datetime),
                                                 :user => changeset_user_link(changeset)
    end
  end

  def changeset_index_title(params, user)
    if params[:friends] && current_user
      t "changesets.index.title_friend"
    elsif params[:nearby] && current_user
      t "changesets.index.title_nearby"
    elsif params[:display_name]
      name = if user.status == "deleted"
               t("users.no_such_user.deleted")
             else
               params[:display_name]
             end
      t "changesets.index.title_user", :user => name
    else
      t "changesets.index.title"
    end
  end
end
