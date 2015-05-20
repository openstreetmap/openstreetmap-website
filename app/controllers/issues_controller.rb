class IssuesController < ApplicationController
  layout "site"

  before_action :find_issue, only: [:show, :resolve, :reopen, :ignore]

  def index
    @issues = Issue.all
  end

  def show
    @read_reports = @issue.read_reports
    @unread_reports = @issue.unread_reports
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
      @admins.each do |user|
        Notifier.new_issue_notification(User.find(user.user_id)).deliver_now
      end
    end

    @report = @issue.reports.build(report_params)

    if @issue.save
      redirect_to @issue, notice: 'Issue was successfully created.'
    else
      render :new
    end
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

    def create_new_issue_params
      params.permit(:reportable_id, :reportable_type, :user_id)
    end

    def issue_params
      params[:issue].permit(:reportable_id, :reportable_type,:user_id)
    end

    def report_params
      params[:report].permit(:details)
    end
end
