module ChangesetHelper
    def changeset_time_ago(changeset)
        out = ''
        created_at = distance_of_time_in_words_to_now(changeset.created_at)
        closed_at = distance_of_time_in_words_to_now(changeset.closed_at)
        if created_at == closed_at
            out << t('browse.changeset_details.closed_at') + ' '
            both_times = t('browse.changeset_details.created_at') + ': ' + l(changeset.created_at)
            both_times << '&#10;'
            both_times << t('browse.changeset_details.closed_at') + ': ' + l(changeset.closed_at)
            out << content_tag(:abbr, t('browse.changeset_details.ago', :ago => created_at), title: both_times.html_safe)
        else
            out << t('browse.changeset_details.created_at') + ' '
            out << content_tag(:abbr, t('browse.changeset_details.ago', :ago => created_at), title: l(changeset.created_at))
            out << t('browse.changeset_details.closed_at') + ' '
            out << content_tag(:abbr, t('browse.changeset_details.ago', :ago => closed_at), title: l(changeset.closed_at))
        end
        if changeset.user.data_public?
            out << ' ' + t('browse.changeset_details.by') + ' '
            out << link_to(h(changeset.user.display_name), :controller => "user", :action => "view", :display_name => changeset.user.display_name)
        end
        return out.html_safe
    end
end
