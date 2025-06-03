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

      case params[:avatar_action]
      when "new"
        current_user.avatar.attach(params[:user][:avatar])
        current_user.image_use_gravatar = false
      when "delete"
        current_user.avatar.purge_later
        current_user.image_use_gravatar = false
      when "gravatar"
        current_user.avatar.purge_later
        current_user.image_use_gravatar = true
      end

      current_user.save
    end
  end
end
