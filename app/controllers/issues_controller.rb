class IssuesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :find_issue, :only => [:show, :resolve, :reopen, :ignore]

  def index
    @title = t ".title"

    @issue_types = []
    @issue_types.concat %w[Note] if current_user.moderator?
    @issue_types.concat %w[DiaryEntry DiaryComment User] if current_user.administrator?

    @users = User.joins(:roles).where(:user_roles => { :role => current_user.roles.map(&:role) }).distinct
    @issues = Issue.visible_to(current_user)

    # If search
    if params[:search_by_user]&.present?
      @find_user = User.find_by(:display_name => params[:search_by_user])
      if @find_user
        @issues = @issues.where(:reported_user_id => @find_user.id)
      else
        @issues = @issues.none
        flash.now[:warning] = t(".user_not_found")
      end
    end

    @issues = @issues.where(:status => params[:status]) if params[:status]&.present?

    @issues = @issues.where(:reportable_type => params[:issue_type]) if params[:issue_type]&.present?

    if params[:last_updated_by]&.present?
      last_updated_by = params[:last_updated_by].to_s == "nil" ? nil : params[:last_updated_by].to_i
      @issues = @issues.where(:updated_by => last_updated_by)
    end
  end

  def show
    @read_reports = @issue.read_reports
    @unread_reports = @issue.unread_reports
    @comments = @issue.comments
    @related_issues = @issue.reported_user.issues.where(:assigned_role => current_user.roles.map(&:role)) if @issue.reported_user
    @new_comment = IssueComment.new(:issue => @issue)
  end

  # Status Transistions
  def resolve
    if @issue.resolve
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
