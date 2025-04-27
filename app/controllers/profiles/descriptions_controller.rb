# frozen_string_literal: true

module Profiles
  class DescriptionsController < ProfileSectionsController
    private

    def update_profile
      if params[:user][:description] != current_user.description
        current_user.description = params[:user][:description]
        current_user.description_format = "markdown"
      end

      current_user.save
    end
  end
end
