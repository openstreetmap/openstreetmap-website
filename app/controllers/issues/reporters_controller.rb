module Issues
  class ReportersController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :issue

    def index
      @issue = Issue.visible_to(current_user).find(params[:issue_id])

      user_ids = @issue.reports.reorder(:created_at => :desc).pluck(:user_id).uniq
      @unique_reporters = {
        @issue.id => {
          :count => user_ids.size,
          :users => User.in_order_of(:id, user_ids)
        }
      }

      render :partial => "reporters", :locals => { :issue => @issue } if turbo_frame_request?
    rescue ActiveRecord::RecordNotFound
      redirect_to :controller => "/errors", :action => "not_found"
    end
  end
end
