# frozen_string_literal: true

module Profiles
  class HeatmapsController < ProfileSectionsController
    private

    def update_profile
      current_user.update(:public_heatmap => params[:user][:public_heatmap])
    end
  end
end
