module ChangesetsHelper
  def changeset_user_link(changeset)
    if changeset.user.status == "deleted"
      t("users.no_such_user.deleted")
    elsif changeset.user.data_public?
      link_to(changeset.user.display_name, user_path(changeset.user))
    else
      t("browse.anonymous")
    end
  end

  def changeset_details(changeset)
    if changeset.closed_at > Time.now
      action = :created
      time = time_ago_in_words(changeset.created_at, :scope => :'datetime.distance_in_words_ago')
      title = l(changeset.created_at)
    else
      action = :closed
      time = time_ago_in_words(changeset.closed_at, :scope => :'datetime.distance_in_words_ago')
      title = "#{t('browse.created')}: #{l(changeset.created_at)}&#10;#{t('browse.closed')}: #{l(changeset.closed_at)}".html_safe
    end

    if params.key?(:display_name)
      t "browse.#{action}_html",
        :time => time,
        :title => title
    else
      t "browse.#{action}_by_html",
        :time => time,
        :title => title,
        :user => changeset_user_link(changeset)
    end
  end

  def changeset_index_title(params, user)
    if params[:friends] && user
      t "changesets.index.title_friend"
    elsif params[:nearby] && user
      t "changesets.index.title_nearby"
    elsif params[:display_name]
      t "changesets.index.title_user", :user => params[:display_name]
    else
      t "changesets.index.title"
    end
  end
end
