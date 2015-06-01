class IssuesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :require_user
  before_action :check_permission, only: [:index, :show, :resolve,:open,:ignore,:comment]
  before_action :find_issue, only: [:show, :resolve, :reopen, :ignore]

  def index
    @issues = Issue.all
  end

  def show
    @read_reports = @issue.read_reports
    @unread_reports = @issue.unread_reports
    @comments = @issue.comments
    @related_issues = @issue.user.issues
  end

  def new
    unless create_new_issue_params.blank?
      @issue = Issue.find_or_initialize_by(create_new_issue_params)
    end
  end

  def create
    @issue = Issue.find_by_reportable_id_and_reportable_type(params[:reportable_id],params[:reportable_type])
    if !@issue 
      @issue = Issue.find_or_initialize_by(issue_params)
      @admins = UserRole.where(role: "administrator")
      @admins.each do |admin|
        Notifier.new_issue_notification(User.find(admin.user_id)).deliver_now
      end
    end
    @report = @issue.reports.build(report_params)
    @report.user_id = @user.id
    if @issue.save!
      redirect_to root_path, notice: 'Your report has been registered sucessfully.'
    else
      render :new
    end
  end

  def comment
    @issue = Issue.find(params[:id])
    @issue_comment = @issue.comments.build(issue_comment_params)
    @issue_comment.user_id = @user.id
    @issue_comment.save!
    redirect_to @issue
  end

  # Status Transistions
  def resolve
    if @issue.resolve
      @issue.save!
      redirect_to @issue, notice: "Issue status has been set to: 'Resolved'"
    else
      render :show
    end
  end

  def ignore
    if @issue.ignore
      @issue.save!
      redirect_to @issue, notice: "Issue status has been set to: 'Ignored'"
    else
      render :show
    end
  end

  def reopen
    if @issue.reopen
      @issue.save!
      redirect_to @issue, notice: "Issue status has been set to: 'Open'"
    else
      render :show
    end
  end

  private

    def find_issue
      @issue = Issue.find(params[:id])
    end

    def check_permission
      unless @user.administrator?
        flash[:error] = t("application.require_admin.not_an_admin")
        redirect_to root_path
      end
    end

    def create_new_issue_params
      params.permit(:reportable_id, :reportable_type, :reported_user_id)
    end

    def issue_params
      params[:issue].permit(:reportable_id, :reportable_type,:reported_user_id)
    end

    def report_params
      params[:report].permit(:details)
    end

    def issue_comment_params
      params.require(:issue_comment).permit(:body, :user_id)
    end
end
