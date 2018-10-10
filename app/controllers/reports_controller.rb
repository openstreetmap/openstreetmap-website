class ReportsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  def new
    if required_new_report_params_present?
      @report = Report.new
      @report.issue = Issue.find_or_initialize_by(create_new_report_params)
    else
      redirect_to root_path, :notice => t(".missing_params")
    end
  end

  def create
    @report = current_user.reports.new(report_params)
    @report.issue = Issue
                    .create_with(:assigned_role => default_assigned_role)
                    .find_or_initialize_by(issue_params)

    if @report.save
      @report.issue.assigned_role = "administrator" if default_assigned_role == "administrator"
      @report.issue.reopen unless @report.issue.open?
      @report.issue.save!

      redirect_to helpers.reportable_url(@report.issue.reportable), :notice => t(".successful_report")
    else
      redirect_to new_report_path(:reportable_type => @report.issue.reportable_type, :reportable_id => @report.issue.reportable_id), :notice => t(".provide_details")
    end
  end

  private

  def required_new_report_params_present?
    create_new_report_params["reportable_id"].present? && create_new_report_params["reportable_type"].present?
  end

  def create_new_report_params
    params.permit(:reportable_id, :reportable_type)
  end

  def report_params
    params.require(:report).permit(:details, :category)
  end

  def issue_params
    params.require(:report).require(:issue).permit(:reportable_id, :reportable_type)
  end

  def default_assigned_role
    case issue_params[:reportable_type]
    when "Note" then "moderator"
    when "User" then case report_params[:category]
                     when "vandal" then "moderator"
                     else "administrator"
                     end
    else "administrator"
    end
  end
end
