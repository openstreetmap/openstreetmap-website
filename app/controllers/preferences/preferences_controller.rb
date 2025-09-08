# frozen_string_literal: true

module Preferences
  class PreferencesController < ApplicationController
    layout :site_layout

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => :preferences

    before_action :check_database_readable
    before_action :check_database_writable, :only => :update

    def show; end

    def update
      if update_preferences
        # Use a partial so that it is rendered during the next page load in the correct language.
        flash[:notice] = { :partial => "preferences/preferences/update_success_flash" }
        referer = safe_referer(params[:referer]) if params[:referer]
        redirect_to referer || { :action => :show }
      else
        flash.now[:error] = t "failure", :scope => "preferences.preferences.update"
        render :show
      end
    end
  end
end
