class PreferencesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false

  before_action :check_database_readable
  before_action :check_database_writable, :only => [:update]

  def show; end

  def update
    current_user.languages = params[:user][:languages].split(",")

    current_user.preferred_editor = if params[:user][:preferred_editor] == "default"
                                      nil
                                    else
                                      params[:user][:preferred_editor]
                                    end

    success = current_user.save

    if params[:site_color_scheme]
      site_color_scheme_preference = current_user.preferences.find_or_create_by(:k => "site.color_scheme")
      success &= site_color_scheme_preference.update(:v => params[:site_color_scheme])
    end

    if params[:map_color_scheme]
      map_color_scheme_preference = current_user.preferences.find_or_create_by(:k => "map.color_scheme")
      success &= map_color_scheme_preference.update(:v => params[:map_color_scheme])
    end

    if success
      # Use a partial so that it is rendered during the next page load in the correct language.
      flash[:notice] = { :partial => "preferences/update_success_flash" }
      redirect_to preferences_path
    else
      flash.now[:error] = t ".failure"
      render :show
    end
  end
end
