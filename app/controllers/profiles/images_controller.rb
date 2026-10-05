# frozen_string_literal: true

module Profiles
  class ImagesController < ProfileSectionsController
    private

    def update_profile
      case params[:avatar_action]
      when "new"
        current_user.avatar.attach(params.dig(:user, :avatar))
        current_user.image_use_gravatar = false
      when "delete"
        current_user.avatar.purge_later
        current_user.image_use_gravatar = false
      when "gravatar"
        current_user.avatar.purge_later
        current_user.image_use_gravatar = true
      end

      saved_user = current_user.save

      current_user.attachment_changes.delete("avatar") unless saved_user

      saved_user
    end
  end
end
