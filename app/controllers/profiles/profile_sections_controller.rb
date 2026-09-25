# frozen_string_literal: true

module Profiles
  class ProfileSectionsController < ApplicationController
    layout :site_layout

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => :profile

    before_action :check_database_readable
    before_action :check_database_writable, :only => [:update]

    def show; end

    def update
      if update_profile
        flash[:notice] = t ".success"
        redirect_to user_path(current_user)
      else
        flash.now[:error] = t ".failure"
        render :show
      end
    end
  end
end
