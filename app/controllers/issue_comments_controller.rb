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

    if params[:reassign]
      reassign_issue(@issue)
      flash[:notice] = t ".issue_reassigned"

      if current_user.has_role? @issue.assigned_role
        redirect_to @issue
      else
        redirect_to issues_path(:status => "open")
      end
    else
      flash[:notice] = t(".comment_created")
      redirect_to @issue
    end
  end

  private

  def issue_comment_params
    params.require(:issue_comment).permit(:body)
  end

  # This sort of assumes there are only two roles
  def reassign_issue(issue)
    role = (Issue::ASSIGNED_ROLES - [issue.assigned_role]).first
    issue.assigned_role = role
    issue.save!
  end
end
