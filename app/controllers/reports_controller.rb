class ReportsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :require_user

  def new
    if required_new_report_params_present?
      @report = Report.new
      @report.issue = Issue.find_or_initialize_by(create_new_report_params)
    else
      redirect_to root_path, :notice => t("reports.new.missing_params")
    end
  end

  def create
    @report = current_user.reports.new(report_params)
    @report.issue = Issue.find_or_initialize_by(:reportable_id => params[:report][:issue][:reportable_id], :reportable_type => params[:report][:issue][:reportable_type])

    if @report.save
      @report.issue.save
      @report.issue.reopen! unless @report.issue.open?
      redirect_to root_path, :notice => t("issues.create.successful_report")
    else
      redirect_to new_report_path(:reportable_type => @report.issue.reportable_type, :reportable_id => @report.issue.reportable_id), :notice => t("issues.create.provide_details")
    end
  end

  private

  def required_new_report_params_present?
    create_new_report_params['reportable_id'].present? && create_new_report_params['reportable_type'].present?
  end

  def create_new_report_params
    params.permit(:reportable_id, :reportable_type)
  end

  def report_params
    params[:report].permit(:details, :category)
  end
end
