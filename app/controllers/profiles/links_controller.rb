# frozen_string_literal: true

module Profiles
  class LinksController < ProfileSectionsController
    private

    def update_profile
      social_links_params = params.permit(:user => [:social_links_attributes => [:id, :url, :_destroy]])
      current_user.assign_attributes(social_links_params[:user])

      current_user.save
    end
  end
end
