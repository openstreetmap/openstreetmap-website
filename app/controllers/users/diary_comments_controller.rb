module Users
  class DiaryCommentsController < CommentsController
    include ActionView::Helpers::TagHelper

    def index
      @title = t ".title_html", :user => tag.bdi(@user.display_name)

      comments = DiaryComment.where(:user => @user)
      comments = comments.visible unless can? :unhide, DiaryComment

      @params = params.permit(:display_name, :before, :after)

      @comments, @newer_comments_id, @older_comments_id = get_page_items(comments, :includes => [:user, :diary_entry])

      render :partial => "page" if turbo_frame_request_id == "pagination"
    end
  end
end
