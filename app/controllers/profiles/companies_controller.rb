# frozen_string_literal: true

module Profiles
  class CompaniesController < ProfileSectionsController
    private

    def update_profile
      current_user.company = params[:user][:company]

      current_user.save
    end
  end
end
