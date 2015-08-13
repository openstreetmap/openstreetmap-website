class IssuesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :require_user
  before_action :set_issues
  before_action :check_permission, only: [:index, :show, :resolve,:open,:ignore,:comment]
  before_action :find_issue, only: [:show, :resolve, :reopen, :ignore]
  before_action :get_user_role, only: [:show, :index]

  helper_method :sort_column, :sort_direction

  def index
    if @user.moderator?
      @issue_types = @moderator_issues
      @users = User.joins(:roles).where(user_roles: {role: 'moderator'})
    else
      @issue_types = @admin_issues
      @users = User.joins(:roles).where(user_roles: {role: 'administrator'})
    end

    @issues = Issue.where(issue_type: @user_role).order(sort_column + " " + sort_direction)

    # If search
    if params[:search_by_user] and !params[:search_by_user].blank?
      @find_user = User.find_by_display_name(params[:search_by_user])
      if @find_user
        @issues = @issues.where(reported_user_id: @find_user.id)
      else 
        notice = t('issues.index.search.user_not_found') 
      end
    end


    if params[:status] and !params[:status][0].blank?
      @issues = @issues.where(status: params[:status][0].to_i)
    end

    if params[:issue_type] and !params[:issue_type][0].blank?
      @issues = @issues.where(reportable_type: params[:issue_type][0])
    end

    # If last_updated_by
    if params[:last_updated_by] and !params[:last_updated_by][0].blank?
      last_reported_by = params[:last_updated_by][0].to_s == "nil" ? nil : params[:last_updated_by][0].to_i
      @issues = @issues.where(updated_by: last_updated_by)
    end

    if @issues.first == nil
        notice = t('issues.index.search.issues_not_found')      
    end

    if params[:last_reported_by] and !params[:last_reported_by][0].blank?
      last_reported_by = params[:last_reported_by][0].to_s == "nil" ? nil : params[:last_reported_by][0].to_i
      @issues = @issues.where(updated_by: last_reported_by)
    end

    if notice
      redirect_to issues_path, notice: notice
    end 
  end

  def show
    @read_reports = @issue.read_reports
    @unread_reports = @issue.unread_reports
    @comments = @issue.comments
    @related_issues = @issue.user.issues.where(issue_type: @user_role)
    if @issue.updated_by
      @updated_by_admin = User.find(@issue.updated_by)
    end
  end

  def new
    unless create_new_issue_params.blank?
      @issue = Issue.find_or_initialize_by(create_new_issue_params)
      path = 'issues.report_strings.' + @issue.reportable.class.name.to_s
      @report_strings_yaml = t(path)
      flash[:referer] = params[:referer]
    end
  end

  def create
    @issue = Issue.find_by_reportable_id_and_reportable_type(params[:reportable_id],params[:reportable_type])
    # Check if Issue already exists
    if !@issue 
      @issue = Issue.find_or_initialize_by(issue_params)
      @issue.updated_by = nil

      # Reassign to moderators if it is a moderator issue
      @issue.issue_type = "administrator"
      if @moderator_issues.include? @issue.reportable.class.name
        reassign_issue
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
        @issue.report_count = @issue.reports.count
        @issue.save!
        
        @admins_or_mods = UserRole.where(role: @issue.issue_type)
        @admins_or_mods.each do |user|
          Notifier.new_issue_notification(@issue.id, User.find(user.user_id)).deliver_now
        end

        redirect_to flash[:referer], notice: t('issues.create.successful_report')
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
        @issue.report_count = @issue.reports.count
        @issue.save!
        redirect_to flash[:referer], notice: notice
      end
    else
      redirect_to new_issue_path(reportable_type: @issue.reportable_type,reportable_id: @issue.reportable_id, reported_user_id: @issue.reported_user_id), notice: t('issues.update.provide_details')
    end  
  end

  def comment
    @issue = Issue.find(params[:id])
    if issue_comment_params.blank?
      notice = t('issues.comment.provide_details')
    else
      @issue_comment = @issue.comments.build(issue_comment_params)
      @issue_comment.commenter_user_id = @user.id
      if params[:reassign]
        reassign_issue
        @issue_comment.reassign = true
      end
      @issue_comment.save!
      @issue.updated_by = @user.id
      @issue.save!
      notice = t('issues.comment.comment_created')
    end
    redirect_to @issue, notice: notice
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
      @issue.updated_by = @user.id
      @issue.save!
      redirect_to @issue, notice: t('issues.ignored')
    else
      render :show
    end
  end

  def reopen
    if @issue.reopen
      @issue.updated_by = @user.id      
      @issue.save!
      redirect_to @issue, notice: t('issues.reopened')
    else
      render :show
    end
  end

  # Reassign Issues between Administrators and Moderators
  def reassign_issue
    if @issue.issue_type == "moderator"
      @issue.issue_type = "administrator"
    else
      @issue.issue_type = "moderator"
    end
    @issue.save!
  end

  private

    def set_issues
      @admin_issues = [ 'DiaryEntry', 'DiaryComment', 'User']
      @moderator_issues = [ 'Changeset', 'Note' ]
    end

    def get_user_role
      # Get user role
      if @user.administrator?
        @user_role = "administrator"
      else
        @user_role = "moderator"
      end      
    end
    
    def check_if_updated
      if @issue.reportable and (@issue.ignored? or @issue.resolved?) and @issue.reportable.has_attribute?(:updated_by) and @issue.reportable.updated_at > @last_report.updated_at
        return true
      else
        return false
      end
    end
 
    def get_report_details
      details = params[:report][:details] + "--||--"
      details = details + params[:report_type].to_s + "--||--"
      return details
    end

    def check_report_params
      if params[:report] and params[:report][:details] and params[:report_type]
        return true
      end
      return false
    end

    def find_issue
      @issue = Issue.find(params[:id])
    end

    def check_permission
      unless @user.administrator? or @user.moderator?
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

    def sort_column
      Issue.column_names.include?(params[:sort]) ? params[:sort] : "status"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
end
