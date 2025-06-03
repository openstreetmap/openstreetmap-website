module Profiles
  class DescriptionsController < ProfileSectionsController
    private

    def update_profile
      social_links_params = params.permit(:user => [:social_links_attributes => [:id, :url, :_destroy]])
      current_user.assign_attributes(social_links_params[:user])

      if params[:user][:description] != current_user.description
        current_user.description = params[:user][:description]
        current_user.description_format = "markdown"
      end

      current_user.save
    end
  end
end
