module Users
  class ChangesetCommentsController < CommentsController
    def index
      @title = t ".title", :user => @user.display_name

      comments = ChangesetComment.where(:author => @user)
      comments = comments.visible unless current_user&.moderator?

      @params = params.permit(:display_name, :before, :after)

      @comments, @newer_comments_id, @older_comments_id = get_page_items(comments, :includes => [:author, :changeset])
    end
  end
end
