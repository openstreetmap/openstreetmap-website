# frozen_string_literal: true

module Profiles
  class LocationsController < ProfileSectionsController
    private

    def update_profile
      current_user.home_lat = params[:user][:home_lat]
      current_user.home_lon = params[:user][:home_lon]
      current_user.home_location_name = params[:user][:home_location_name]

      current_user.save
    end
  end
end
