module ChangesetHelper
  def changeset_details(changeset)
    out = ''
    created_at = distance_of_time_in_words_to_now(changeset.created_at)
    closed_at = distance_of_time_in_words_to_now(changeset.closed_at)
    date = ''
    if changeset.closed_at > DateTime.now
      date << t('browse.created') + ' '
      date << content_tag(:abbr, t('browse.ago', :ago => created_at), title: l(changeset.created_at))
    else
      date << t('browse.closed') + ' '
      both_times = t('browse.created') + ': ' + l(changeset.created_at)
      both_times << '&#10;'
      both_times << t('browse.closed') + ': ' + l(changeset.closed_at)
      date << content_tag(:abbr, t('browse.ago', :ago => created_at), title: both_times.html_safe)
    end
    out << content_tag(:span, date.html_safe, class: 'date')
    unless params.key?(:display_name)
      userspan = ''
      if changeset.user.data_public?
        userspan << ' ' + t('browse.by') + ' '
        if changeset.user.data_public?
          user = link_to changeset.user.display_name, user_path(changeset.user.display_name)
        else
          user = t('changeset.changeset.anonymous')
        end
        userspan << content_tag(:span, user, class: 'user')
      end
      out << content_tag(:span, userspan.html_safe, class: 'user')
    end
    return out.html_safe
  end
end
