module ChangesetsHelper
  def changeset_user_link(changeset)
    if changeset.user.status == "deleted"
      t("users.no_such_user.deleted")
    elsif changeset.user.data_public?
      link_to changeset.user.display_name, changeset.user, :class => "mw-100 d-inline-block align-bottom text-truncate text-wrap", :dir => "auto"
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
    if params[:friends] && user
      t "changesets.index.title_followed"
    elsif params[:nearby] && user
      t "changesets.index.title_nearby"
    elsif params[:display_name]
      t "changesets.index.title_user", :user => params[:display_name]
    else
      t "changesets.index.title"
    end
  end

  def changeset_data(changeset)
    changeset_data = { :id => changeset.id }

    if changeset.bbox_valid?
      bbox = changeset.bbox.to_unscaled
      changeset_data[:bbox] = {
        :minlon => bbox.min_lon,
        :minlat => bbox.min_lat,
        :maxlon => bbox.max_lon,
        :maxlat => bbox.max_lat
      }
    end

    changeset_data
  end
end
