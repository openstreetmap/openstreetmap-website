module Profiles
  class ImagesController < ProfileSectionsController
    private

    def update_profile
      current_user.save
    end
  end
end
