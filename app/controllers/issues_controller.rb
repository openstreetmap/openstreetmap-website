class IssuesController < ApplicationController
  include PaginationMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :find_issue, :only => [:show, :resolve, :reopen, :ignore]
  before_action :check_database_writable, :only => [:resolve, :ignore, :reopen]

  def index
    @params = params.permit(:before, :after, :limit, :status, :search_by_user, :issue_type, :last_updated_by)
    @params[:limit] ||= 50
    @title = t ".title"

    @issue_types = []
    @issue_types |= %w[Note User] if current_user.moderator?
    @issue_types |= %w[DiaryEntry DiaryComment User] if current_user.administrator?

    @users = User.joins(:roles).where(:user_roles => { :role => current_user.roles.map(&:role) }).distinct
    @issues = Issue.visible_to(current_user)

    # If search
    if params[:search_by_user].present?
      @find_user = User.find_by(:display_name => params[:search_by_user])
      @issues = if @find_user
                  @issues.where(:reported_user => @find_user)
                else
                  @issues.none
                end
    end

    @issues = @issues.where(:status => params[:status]) if params[:status].present?

    @issues = @issues.where(:reportable_type => params[:issue_type]) if params[:issue_type].present?

    if params[:last_updated_by].present?
      last_updated_by = params[:last_updated_by].to_s == "nil" ? nil : params[:last_updated_by].to_i
      @issues = @issues.where(:updated_by => last_updated_by)
    end

    @issues, @newer_issues_id, @older_issues_id = get_page_items(@issues, :limit => @params[:limit])

    @unique_reporters_limit = 3
    @unique_reporters = @issues.each_with_object({}) do |issue, reporters|
      user_ids = issue.reports.reorder(:created_at => :desc).pluck(:user_id).uniq
      reporters[issue.id] = {
        :count => user_ids.size,
        :users => User.in_order_of(:id, user_ids.first(@unique_reporters_limit))
      }
    end

    render :partial => "page" if turbo_frame_request_id == "pagination"
  end

  def show
    @title = t ".title.#{@issue.status}", :issue_id => @issue.id
    @read_reports = @issue.read_reports
    @unread_reports = @issue.unread_reports
    @comments = @issue.comments
    @related_issues = @issue.reported_user.issues.where(:assigned_role => current_user.roles.map(&:role)) if @issue.reported_user
    @new_comment = IssueComment.new(:issue => @issue)
  end

  # Status Transitions
  def resolve
    if @issue.resolve
      @issue.updated_by = current_user.id
      @issue.save!
      redirect_to @issue, :notice => t(".resolved")
    else
      render :show
    end
  end

  def ignore
    if @issue.ignore
      @issue.updated_by = current_user.id
      @issue.save!
      redirect_to @issue, :notice => t(".ignored")
    else
      render :show
    end
  end

  def reopen
    if @issue.reopen
      @issue.updated_by = current_user.id
      @issue.save!
      redirect_to @issue, :notice => t(".reopened")
    else
      render :show
    end
  end

  private

  def find_issue
    @issue = Issue.visible_to(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to :controller => "errors", :action => "not_found"
  end
end
