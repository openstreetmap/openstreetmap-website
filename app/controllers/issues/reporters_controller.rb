module Issues
  class ReportersController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :issue

    def index
      @issue = Issue.visible_to(current_user).find(params[:issue_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to :controller => "/errors", :action => "not_found"
    end
  end
end
