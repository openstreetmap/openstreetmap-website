class IssueCommentsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :check_database_writable, :only => [:create]

  def create
    @issue = Issue.find(params[:issue_id])
    comment = @issue.comments.build(issue_comment_params)
    comment.user = current_user
    comment.save!

    if params[:reassign]
      reassign_issue(@issue)
      flash[:notice] = t ".issue_reassigned"

      if current_user.role? @issue.assigned_role
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
    params.expect(:issue_comment => [:body])
  end

  # This sort of assumes there are only two roles
  def reassign_issue(issue)
    role = (Issue::ASSIGNED_ROLES - [issue.assigned_role]).first
    issue.assigned_role = role
    issue.save!
  end
end
