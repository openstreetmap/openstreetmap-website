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
    if params[:report][:details] and (params[:spam] or params[:offensive] or params[:threat] or params[:vandal] or params[:other])
      @report = @issue.reports.build(report_params)
      details =  params[:report][:details].to_s + "||" + params[:spam].to_s + "||" + params[:offensive].to_s + "||" + params[:threat].to_s + "||" + params[:vandal].to_s + "||" + params[:other].to_s
      @report.reporter_user_id = @user.id
      @report.details = details
      if @issue.save!
        redirect_to root_path, notice: t('issues.create.successful_report')
      end
    else
      redirect_to new_issue_path(reportable_type: @issue.reportable_type,reportable_id: @issue.reportable_id, reported_user_id: @issue.reported_user_id), notice: t('issues.create.provide_details')
    end
  end

  def update
    @issue = Issue.find_by(issue_params)
    if params[:report][:details] and (params[:spam] or params[:offensive] or params[:threat] or params[:vandal] or params[:other])
      @report = @issue.reports.where(reporter_user_id: @user.id).first
      details =  params[:report][:details].to_s + "||" + params[:spam].to_s + "||" + params[:offensive].to_s + "||" + params[:threat].to_s + "||" + params[:vandal].to_s + "||" + params[:other].to_s
      @report.details = details    
      if @report.save!
        redirect_to root_path, notice: t('issues.update.successful_update')
      end
    else
      redirect_to new_issue_path(reportable_type: @issue.reportable_type,reportable_id: @issue.reportable_id, reported_user_id: @issue.reported_user_id), notice: t('issues.update.provide_details')
    end  
  end

  def comment
    @issue = Issue.find(params[:id])
    @issue_comment = @issue.comments.build(issue_comment_params)
    @issue_comment.commenter_user_id = @user.id
    @issue_comment.save!
    redirect_to @issue
  end

  # Status Transistions
  def resolve
    if @issue.resolve
      @issue.save!
      redirect_to @issue, notice: t('issues.resolved')
    else
      render :show
    end
  end

  def ignore
    if @issue.ignore
      @issue.save!
      redirect_to @issue, notice: t('issues.ignored')
    else
      render :show
    end
  end

  def reopen
    if @issue.reopen
      @issue.save!
      redirect_to @issue, notice: t('issues.reopened')
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
      params.require(:issue_comment).permit(:body)
    end
end
