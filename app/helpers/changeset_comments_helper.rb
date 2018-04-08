module ChangesetCommentsHelper
  def user_comments_link_text(link_user)
    if current_user == link_user
      t "changeset_comments.list.heading_links.current_user_comments"
    else
      t "changeset_comments.list.heading_links.other_user_comments", :user => link_user.display_name
    end
  end

  def user_received_comments_link_text(link_user)
    if current_user == link_user
      t "changeset_comments.list.heading_links.current_user_received_comments"
    else
      t "changeset_comments.list.heading_links.other_user_received_comments", :user => link_user.display_name
    end
  end
end
