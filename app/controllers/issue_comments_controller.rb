class IssueCommentsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  def create
    @issue = Issue.find(params[:issue_id])
    comment = @issue.comments.build(issue_comment_params)
    comment.user = current_user
    comment.save!
    notice = t(".comment_created")
    reassign_issue(@issue) if params[:reassign]
    redirect_to @issue, :notice => notice
  end

  private

  def issue_comment_params
    params.require(:issue_comment).permit(:body)
  end

  def deny_access(_exception)
    if current_user
      flash[:error] = t("application.require_moderator_or_admin.not_a_moderator_or_admin")
      redirect_to root_path
    else
      super
    end
  end

  # This sort of assumes there are only two roles
  def reassign_issue(issue)
    role = (Issue::ASSIGNED_ROLES - [issue.assigned_role]).first
    issue.assigned_role = role
    issue.save!
  end
end
