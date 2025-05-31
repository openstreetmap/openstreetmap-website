module Preferences
  class PreferencesController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => :preferences

    before_action :check_database_readable
    before_action :check_database_writable, :only => :update

    def show; end

    def update
      if update_preferences
        # Use a partial so that it is rendered during the next page load in the correct language.
        flash[:notice] = { :partial => "update_success_flash" }
        redirect_to :action => :show
      else
        flash.now[:error] = t "failure", :scope => "preferences.preferences.update"
        render :show
      end
    end
  end
end
