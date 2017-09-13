class IssueCommentsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :require_user
  before_action :check_permission

  def create
    @issue = Issue.find(params[:issue_id])
    comment = @issue.comments.build(issue_comment_params)
    comment.user = current_user
    # if params[:reassign]
    #   reassign_issue
    #   @issue_comment.reassign = true
    # end
    comment.save!
    notice = t("issues.comment.comment_created")
    redirect_to @issue, :notice => notice
  end

  private

  def issue_comment_params
    params.require(:issue_comment).permit(:body)
  end

  def check_permission
    unless current_user.administrator? || current_user.moderator?
      flash[:error] = t("application.require_admin.not_an_admin")
      redirect_to root_path
    end
  end
end
