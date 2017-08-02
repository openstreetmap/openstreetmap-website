class IssuesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :require_user
  before_action :set_issues
  before_action :check_permission, :only => [:index, :show, :resolve, :open, :ignore, :comment]
  before_action :find_issue, :only => [:show, :resolve, :reopen, :ignore]
  before_action :setup_user_role, :only => [:show, :index]

  helper_method :sort_column, :sort_direction

  def index
    if current_user.moderator?
      @issue_types = @moderator_issues
      @users = User.joins(:roles).where(:user_roles => { :role => "moderator" })
    else
      @issue_types = @admin_issues
      @users = User.joins(:roles).where(:user_roles => { :role => "administrator" })
    end

    @issues = Issue.where(:issue_type => @user_role).order(sort_column + " " + sort_direction)

    # If search
    if params[:search_by_user] && params[:search_by_user].present?
      @find_user = User.find_by(:display_name => params[:search_by_user])
      if @find_user
        @issues = @issues.where(:reported_user_id => @find_user.id)
      else
        notice = t("issues.index.search.user_not_found")
      end
    end

    if params[:status] && params[:status][0].present?
      @issues = @issues.where(:status => params[:status][0].to_i)
    end

    if params[:issue_type] && params[:issue_type][0].present?
      @issues = @issues.where(:reportable_type => params[:issue_type][0])
    end

    # If last_updated_by
    if params[:last_updated_by] && params[:last_updated_by][0].present?
      last_updated_by = params[:last_updated_by][0].to_s == "nil" ? nil : params[:last_updated_by][0].to_i
      @issues = @issues.where(:updated_by => last_updated_by)
    end

    notice = t("issues.index.search.issues_not_found") if @issues.first.nil?

    if params[:last_reported_by] && params[:last_reported_by][0].present?
      last_reported_by = params[:last_reported_by][0].to_s == "nil" ? nil : params[:last_reported_by][0].to_i
      @issues = @issues.where(:updated_by => last_reported_by)
    end

    redirect_to issues_path, :notice => notice if notice
  end

  def show
    @read_reports = @issue.read_reports
    @unread_reports = @issue.unread_reports
    @comments = @issue.comments
    @related_issues = @issue.reported_user.issues.where(:issue_type => @user_role)
  end

  def new
    if create_new_issue_params.present?
      @issue = Issue.find_or_initialize_by(create_new_issue_params)
      path = "issues.report_strings." + @issue.reportable.class.name.to_s
      @report_strings_yaml = t(path)
    end
  end

  def create
    @issue = Issue.find_by(:reportable_id => params[:reportable_id], :reportable_type => params[:reportable_type])
    # Check if Issue already exists
    unless @issue
      @issue = Issue.find_or_initialize_by(issue_params)
      @issue.updated_by = nil

      # Reassign to moderators if it is a moderator issue
      @issue.issue_type = "administrator"
      reassign_issue if @moderator_issues.include? @issue.reportable.class.name
    end

    # Check if details provided are sufficient
    if check_report_params
      @report = @issue.reports.build(report_params)
      details = report_details
      @report.reporter_user_id = current_user.id
      @report.details = details
      # Checking if instance has been updated since last report
      @last_report = @issue.reports.order(:updated_at => :desc).last
      if check_if_updated
        @issue.save! if @issue.reopen
      end

      if @issue.save!
        @issue.report_count = @issue.reports.count
        @issue.save!

        @admins_or_mods = UserRole.where(:role => @issue.issue_type)
        @admins_or_mods.each do |user|
          Notifier.new_issue_notification(@issue.id, User.find(user.user_id)).deliver_now
        end

        redirect_back :fallback_location => "/", :notice => t("issues.create.successful_report")
      end
    else
      redirect_to new_issue_path(:reportable_type => @issue.reportable_type, :reportable_id => @issue.reportable_id), :notice => t("issues.create.provide_details")
    end
  end

  def update
    @issue = Issue.find_by(issue_params)
    # Check if details provided are sufficient
    if check_report_params
      @report = @issue.reports.where(:reporter_user_id => current_user.id).first

      if @report.nil?
        @report = @issue.reports.build(report_params)
        @report.reporter_user_id = current_user.id
        notice = t("issues.update.new_report")
      end

      details = report_details
      @report.details = details

      # Checking if instance has been updated since last report
      @last_report = @issue.reports.order(:updated_at => :desc).last
      if check_if_updated
        @issue.reopen
        @issue.save!
      end

      notice = t("issues.update.successful_update") if notice.nil?

      if @report.save!
        @issue.report_count = @issue.reports.count
        @issue.save!
        redirect_back :fallback_location => "/", :notice => notice
      end
    else
      redirect_to new_issue_path(:reportable_type => @issue.reportable_type, :reportable_id => @issue.reportable_id), :notice => t("issues.update.provide_details")
    end
  end

  def comment
    @issue = Issue.find(params[:id])
    if issue_comment_params.blank?
      notice = t("issues.comment.provide_details")
    else
      @issue_comment = @issue.comments.build(issue_comment_params)
      @issue_comment.commenter_user_id = current_user.id
      if params[:reassign]
        reassign_issue
        @issue_comment.reassign = true
      end
      @issue_comment.save!
      @issue.updated_by = current_user.id
      @issue.save!
      notice = t("issues.comment.comment_created")
    end
    redirect_to @issue, :notice => notice
  end

  # Status Transistions
  def resolve
    if @issue.resolve
      @issue.save!
      redirect_to @issue, :notice => t("issues.resolved")
    else
      render :show
    end
  end

  def ignore
    if @issue.ignore
      @issue.updated_by = current_user.id
      @issue.save!
      redirect_to @issue, :notice => t("issues.ignored")
    else
      render :show
    end
  end

  def reopen
    if @issue.reopen
      @issue.updated_by = current_user.id
      @issue.save!
      redirect_to @issue, :notice => t("issues.reopened")
    else
      render :show
    end
  end

  # Reassign Issues between Administrators and Moderators
  def reassign_issue
    @issue.issue_type = upgrade_issue(@issue.issue_type)
    @issue.save!
  end

  private

  def upgrade_issue(type)
    if type == "moderator"
      "administrator"
    else
      "moderator"
    end
  end

  def set_issues
    @admin_issues = %w[DiaryEntry DiaryComment User]
    @moderator_issues = %w[Changeset Note]
  end

  def setup_user_role
    # Get user role
    @user_role = current_user.administrator? ? "administrator" : "moderator"
  end

  def check_if_updated
    if @issue.reportable && (@issue.ignored? || @issue.resolved?) && @issue.reportable.has_attribute?(:updated_by) && @issue.reportable.updated_at > @last_report.updated_at
      true
    else
      false
    end
  end

  def report_details
    params[:report][:details] + "--||--" + params[:report_type].to_s + "--||--"
  end

  def check_report_params
    params[:report] && params[:report][:details] && params[:report_type]
  end

  def find_issue
    @issue = Issue.find(params[:id])
  end

  def check_permission
    unless current_user.administrator? || current_user.moderator?
      flash[:error] = t("application.require_admin.not_an_admin")
      redirect_to root_path
    end
  end

  def create_new_issue_params
    params.permit(:reportable_id, :reportable_type)
  end

  def issue_params
    params[:issue].permit(:reportable_id, :reportable_type)
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
