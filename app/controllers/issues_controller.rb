class IssuesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :require_user
  before_action :check_permission, only: [:index, :show, :resolve,:open,:ignore,:comment]
  before_action :find_issue, only: [:show, :resolve, :reopen, :ignore]

  def index
    if params[:search_by_user].present?
      @user = User.find_by_display_name(params[:search_by_user])
      if @user.present?
        @issues = Issue.where(reported_user_id: @user.id).order(:status)
      else 
        @issues = Issue.all.order(:status)
        redirect_to issues_path, notice: t('issues.index.search.user_not_found') 
      end
      
      if @user.present? and not @issues.present?
        @issues = Issue.all.order(:status)
        redirect_to issues_path, notice: t('issues.index.search.issues_not_found')
      end
    else
      @issues = Issue.all.order(:status)
    end
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
      path = 'issues.report_strings.' + @issue.reportable.class.name.to_s
      @report_strings_yaml = t( path)
    end
  end

  def create
    @issue = Issue.find_by_reportable_id_and_reportable_type(params[:reportable_id],params[:reportable_type])
    # Check if Issue alrwady exists
    if !@issue 
      @issue = Issue.find_or_initialize_by(issue_params)
      @admins = UserRole.where(role: "administrator")
      @admins.each do |admin|
        Notifier.new_issue_notification(User.find(admin.user_id)).deliver_now
      end
    end

    # Check if details provided are sufficient
    if check_report_params
      @report = @issue.reports.build(report_params)
      details =  get_report_details
      @report.reporter_user_id = @user.id
      @report.details = details

      # Checking if instance has been updated since last report
      @last_report = @issue.reports.order(updated_at: :desc).last
      if check_if_updated
        if @issue.reopen
          @issue.save!
        end
      end

      if @issue.save!
        redirect_to root_path, notice: t('issues.create.successful_report')
      end
    else
      redirect_to new_issue_path(reportable_type: @issue.reportable_type,reportable_id: @issue.reportable_id, reported_user_id: @issue.reported_user_id), notice: t('issues.create.provide_details')
    end
  end

  def update
    @issue = Issue.find_by(issue_params)
    # Check if details provided are sufficient
    if check_report_params
      @report = @issue.reports.where(reporter_user_id: @user.id).first
      
      if @report == nil
        @report = @issue.reports.build(report_params)
        @report.reporter_user_id = @user.id
        notice = t('issues.update.new_report')
      end

      details =  get_report_details
      @report.details = details    

    # Checking if instance has been updated since last report
      @last_report = @issue.reports.order(updated_at: :desc).last
      if check_if_updated
        @issue.reopen
        @issue.save!
      end

      if notice == nil
        notice = t('issues.update.successful_update')
      end

      if @report.save!
        redirect_to root_path, notice: notice
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

    def check_if_updated
      if @issue.reportable and (@issue.ignored? or @issue.resolved?) and @issue.reportable.updated_at > @last_report.updated_at
        return true
      else
        return false
      end
    end
 
    def get_report_details
      details = params[:report][:details] + "--||--"
      path = 'issues.report_strings.' + @issue.reportable.class.name.to_s
      @report_strings_yaml = t( path)
      @report_strings_yaml.each do |k,v|
        if params[k.to_sym]
          details = details + params[k.to_sym] + "--||--"
        end
      end
      return details
    end

    def check_report_params
      path = 'issues.report_strings.' + @issue.reportable.class.name.to_s
      @report_strings_yaml = t( path)
      if params[:report] and params[:report][:details]
        @report_strings_yaml.each do |k,v|
          if params[k.to_sym]
            return true
          end
        end
      end
      return false
    end

    def find_issue
      @issue = Issue.find(params[:id])
    end

    def check_permission
      unless @user.administrator?
        flash[:error] = t('application.require_admin.not_an_admin')
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
